import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

import json
import shutil
import tempfile
import traceback
from pathlib import Path

import numpy as np
from PIL import Image as PILImage

from app.core.config import MODEL_PATH

try:
    import h5py
except ImportError:
    h5py = None

try:
    import keras
except ImportError:
    keras = None
    KERAS_FUNCTIONAL_CLASS = None
else:
    try:
        from keras.src.models.functional import Functional as KERAS_FUNCTIONAL_CLASS
    except Exception:
        KERAS_FUNCTIONAL_CLASS = None

try:
    import tensorflow as tf
except ImportError as exc:
    tf = None
    KERAS_LAYER_BASE = object
    TF_IMPORT_ERROR = str(exc)
else:
    try:
        if keras is not None:
            KERAS_LAYER_BASE = keras.layers.Layer
        else:
            KERAS_LAYER_BASE = tf.keras.layers.Layer
    except Exception as exc:
        tf = None
        KERAS_LAYER_BASE = object
        TF_IMPORT_ERROR = str(exc)
    else:
        TF_IMPORT_ERROR = None


DEPENDENCY_ERROR = None
if TF_IMPORT_ERROR:
    DEPENDENCY_ERROR = (
        "TensorFlow/Keras indisponible: "
        f"{TF_IMPORT_ERROR}. Installez `tensorflow` et `keras` dans l'environnement backend."
    )
elif h5py is None:
    DEPENDENCY_ERROR = "h5py indisponible: installez la dependance backend requise."
elif keras is None:
    DEPENDENCY_ERROR = (
        "Keras indisponible dans l'environnement backend. "
        "Installez `keras` (par exemple la version 3.13.2 utilisee dans Colab)."
    )


def _keras_serializable():
    if keras is not None:
        return keras.saving.register_keras_serializable()
    if tf is None:
        return lambda cls: cls
    return tf.keras.utils.register_keras_serializable()


if tf is not None:
    # =========================
    # GPU CONFIG
    # =========================
    gpus = tf.config.list_physical_devices("GPU")
    for gpu in gpus:
        try:
            tf.config.experimental.set_memory_growth(gpu, True)
        except Exception:
            pass


# =========================
# CLASS LABELS
# =========================
CLASS_NAMES = [
    "Melanocytic nevi",
    "Melanoma",
    "Benign keratosis-like lesions",
    "Basal cell carcinoma",
    "Actinic keratoses",
    "Vascular lesions",
    "Dermatofibroma",
]


@_keras_serializable()
class SoftAttention(KERAS_LAYER_BASE):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def call(self, inputs, *args, **kwargs):
        return inputs

    def get_config(self):
        return super().get_config()


@_keras_serializable()
class DWT(KERAS_LAYER_BASE):
    def __init__(self, wavelet_name="haar", concat=0, **kwargs):
        super().__init__(**kwargs)
        self.wavelet_name = wavelet_name
        self.concat = concat

    def call(self, x, *args, **kwargs):
        x = tf.cast(x, tf.float32)
        x01 = x[:, 0::2, :, :] / 2
        x02 = x[:, 1::2, :, :] / 2
        x1, x2 = x01[:, :, 0::2, :], x02[:, :, 0::2, :]
        x3, x4 = x01[:, :, 1::2, :], x02[:, :, 1::2, :]
        return tf.concat([
            x1 + x2 + x3 + x4,
            -x1 - x2 + x3 + x4,
            -x1 + x2 - x3 + x4,
            x1 - x2 - x3 + x4
        ], axis=-1)

    def get_config(self):
        config = super().get_config()
        config.update({"wavelet_name": self.wavelet_name, "concat": self.concat})
        return config

    @classmethod
    def from_config(cls, config):
        return cls(**config)


@_keras_serializable()
class Gradients(KERAS_LAYER_BASE):
    def call(self, inputs, *args, **kwargs):
        dy, dx = tf.image.image_gradients(inputs)
        return tf.sqrt(tf.square(dx) + tf.square(dy))


@_keras_serializable()
class TrueDivide(KERAS_LAYER_BASE):
    def call(self, inputs, *args, **kwargs):
        return inputs[0] / (inputs[1] + 1e-7)


@_keras_serializable()
class ExpandDims(KERAS_LAYER_BASE):
    def __init__(self, axis=-1, **kwargs):
        super().__init__(**kwargs)
        self.axis = axis

    def call(self, inputs, *args, **kwargs):
        return tf.expand_dims(inputs, axis=self.axis)

    def get_config(self):
        config = super().get_config()
        config.update({"axis": self.axis})
        return config


@_keras_serializable()
class OneMinusTensor(KERAS_LAYER_BASE):
    """
    Computes `scalar - inputs` element-wise.
    Replaces Subtract nodes that were saved as Subtract(1, tensor) in Keras 2.
    Keras 3 rejects scalars as positional args; this layer hard-codes the scalar.
    """
    def __init__(self, scalar=1, **kwargs):
        super().__init__(**kwargs)
        self.scalar = scalar

    def call(self, inputs, *args, **kwargs):
        return tf.cast(self.scalar, inputs.dtype) - inputs

    def get_config(self):
        config = super().get_config()
        config.update({"scalar": self.scalar})
        return config


CUSTOM_OBJECTS = {
    "SoftAttention": SoftAttention,
    "DWT": DWT,
    "Gradients": Gradients,
    "TrueDivide": TrueDivide,
    "ExpandDims": ExpandDims,
    "OneMinusTensor": OneMinusTensor,
    "__main__.SoftAttention": SoftAttention,
    "__main__.DWT": DWT,
    "__main__.Gradients": Gradients,
    "__main__.TrueDivide": TrueDivide,
    "__main__.ExpandDims": ExpandDims,
}

if KERAS_FUNCTIONAL_CLASS is not None:
    CUSTOM_OBJECTS["Functional"] = KERAS_FUNCTIONAL_CLASS

# Register globally so nested model deserialization finds them too
if tf is not None:
    if keras is not None:
        keras.saving.get_custom_objects().update(CUSTOM_OBJECTS)
    else:
        tf.keras.utils.get_custom_objects().update(CUSTOM_OBJECTS)


# =========================
# NODE ARGS FIXER
# =========================
def _is_keras_tensor(obj):
    return isinstance(obj, dict) and obj.get("class_name") == "__keras_tensor__"


def _needs_wrapping(args):
    if not isinstance(args, list) or len(args) < 2:
        return False
    if isinstance(args[0], list):
        return False  # already wrapped (Dot / Concatenate)
    return all(_is_keras_tensor(a) for a in args)


def _fix_node(node):
    if not isinstance(node, dict):
        return node
    args = node.get("args", [])
    if _needs_wrapping(args):
        node["args"] = [args]
    return node


def _has_scalar_arg(args):
    return (
        isinstance(args, list)
        and len(args) >= 2
        and any(isinstance(a, (int, float)) for a in args)
    )


def _extract_scalar_and_tensor(args):
    scalar = next(a for a in args if isinstance(a, (int, float)))
    tensor = next(a for a in args if _is_keras_tensor(a))
    return scalar, tensor


# =========================
# RECURSIVE CONFIG PATCHER
# =========================
def _patch_layers(layers):
    for layer in layers:
        config = layer.get("config", {})

        # Strip "Custom>" prefix
        if ">" in layer.get("class_name", ""):
            layer["class_name"] = layer["class_name"].split(">")[-1]

        # Fix InputLayer
        if layer.get("class_name") == "InputLayer":
            config.pop("batch_shape", None)
            config.pop("optional", None)
            config["input_shape"] = [256, 256, 3]

        # Fix DTypePolicy stored as dict
        if "dtype" in config and isinstance(config["dtype"], dict):
            config["dtype"] = "float32"

        # Rewrite Subtract(scalar, tensor) -> OneMinusTensor(tensor)
        # Also rename the layer so weight loading matches by name
        inbound = layer.get("inbound_nodes", [])
        if layer.get("class_name") == "Subtract" and inbound:
            new_nodes = []
            became_one_minus = False
            for node in inbound:
                if isinstance(node, dict):
                    args = node.get("args", [])
                    if _has_scalar_arg(args):
                        scalar, tensor_ref = _extract_scalar_and_tensor(args)
                        node["args"] = [tensor_ref]
                        config["scalar"] = scalar
                        became_one_minus = True
                new_nodes.append(node)
            layer["inbound_nodes"] = new_nodes
            if became_one_minus:
                layer["class_name"] = "OneMinusTensor"
                # Keep config["name"] unchanged so weight loading by_name still works
                # (OneMinusTensor has no weights, so name matching is irrelevant here)

        # Fix remaining multi-tensor inbound_nodes
        if layer.get("inbound_nodes"):
            layer["inbound_nodes"] = [_fix_node(n) for n in layer["inbound_nodes"]]
        if config.get("inbound_nodes"):
            config["inbound_nodes"] = [_fix_node(n) for n in config["inbound_nodes"]]

        # Recurse into nested Functional sub-models
        if "layers" in config:
            _patch_layers(config["layers"])


# =========================
# PATCH H5 FILE
# =========================
def patch_model(src, dst):
    if h5py is None:
        raise RuntimeError("h5py est requis pour patcher le modele.")
    shutil.copy2(src, dst)

    with h5py.File(dst, "r+") as f:
        raw = f.attrs["model_config"]
        if isinstance(raw, bytes):
            raw = raw.decode("utf-8")

        cfg = json.loads(raw)
        _patch_layers(cfg["config"]["layers"])
        f.attrs["model_config"] = json.dumps(cfg)

    print("Patch applied")


# =========================
# LOAD: config first, weights second (by name)
# =========================
def load_model_patched(path):
    """
    Load a Keras 2 H5 model that has been config-patched for Keras 3.

    We cannot use load_model() directly because it loads weights by index,
    and our config patch changes the layer count (Subtract -> OneMinusTensor
    is a different class but same name, so weight groups differ by count).

    Instead:
      1. Reconstruct the model from config only (no weights).
      2. Load weights by name, skipping layers with no matching group.
    """
    if tf is None:
        raise RuntimeError("TensorFlow est requis pour charger le modele.")
    if keras is None:
        raise RuntimeError("Keras est requis pour charger le modele.")
    if h5py is None:
        raise RuntimeError("h5py est requis pour charger le modele.")

    custom_object_scope = (
        keras.saving.custom_object_scope
        if keras is not None
        else tf.keras.utils.custom_object_scope
    )

    with custom_object_scope(CUSTOM_OBJECTS):
        # Step 1: build model from patched config
        with h5py.File(path, "r") as f:
            raw = f.attrs["model_config"]
            if isinstance(raw, bytes):
                raw = raw.decode("utf-8")
            cfg = json.loads(raw)

        model = (keras.models if keras is not None else tf.keras.models).model_from_json(
            json.dumps(cfg),
            custom_objects=CUSTOM_OBJECTS,
        )

        # Step 2: load weights by name; tolerates layer count differences
        model.load_weights(path, by_name=True, skip_mismatch=True)

    return model


# =========================
# AI SERVICE
# =========================
class AiService:
    def __init__(self):
        self.model_path = MODEL_PATH
        self.model = None
        self._load_error = DEPENDENCY_ERROR
        self._patched_model_path = None

    def _patched_copy_path(self):
        src = Path(self.model_path)
        patched_name = f"{src.stem}.{os.getpid()}.patched{src.suffix}"
        return str(Path(tempfile.gettempdir()) / patched_name)

    def _ensure_model_loaded(self):
        if self.model or self._load_error:
            return
        if not Path(self.model_path).exists():
            self._load_error = f"Modele introuvable: {self.model_path}"
            return

        try:
            patched = self._patched_copy_path()
            print("Patching model...")
            patch_model(self.model_path, patched)

            print("Loading model...")
            self.model = load_model_patched(patched)
            self._patched_model_path = patched
            print("Model loaded")

        except Exception as e:
            self._load_error = str(e)
            print("Model loading error:", e)
            traceback.print_exc()

    def get_model_status(self):
        self._ensure_model_loaded()
        return (self.model is not None, self._load_error or None)

    def predict(self, path):
        self._ensure_model_loaded()
        if self.model is None:
            raise RuntimeError(self._load_error)

        img = PILImage.open(path).convert("RGB").resize((256, 256))
        img = np.array(img) / 255.0
        img = np.expand_dims(img, 0)

        pred = self.model.predict(img, verbose=0)
        if isinstance(pred, list):
            pred = pred[0]

        idx = int(np.argmax(pred))
        return CLASS_NAMES[idx], float(pred[0][idx])


ai_service = AiService()
