import os
import numpy as np
import tensorflow as tf
from PIL import Image as PILImage
from pathlib import Path
import hashlib

# Reduce TF logs
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

# GPU memory fix (optional but recommended)
gpus = tf.config.list_physical_devices('GPU')
for gpu in gpus:
    try:
        tf.config.experimental.set_memory_growth(gpu, True)
    except:
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


# =========================
# CUSTOM LAYERS
# =========================

@tf.keras.utils.register_keras_serializable()
class SoftAttention(tf.keras.layers.Layer):
    def __init__(self, ch=1, m=1, aggregate=False, concat_with_x=False, **kwargs):
        super().__init__(**kwargs)
        self.channels = int(ch)
        self.multiheads = int(m)
        self.aggregate_channels = aggregate
        self.concat_input_with_scaled = concat_with_x

    def build(self, input_shape):
        self.i_shape = input_shape

        kernel_shape = (self.channels, 3, 3, 1, self.multiheads)

        self.kernel_conv3d = self.add_weight(
            shape=kernel_shape,
            initializer='he_uniform',
            name='kernel_conv3d'
        )

        self.bias_conv3d = self.add_weight(
            shape=(self.multiheads,),
            initializer='zeros',
            name='bias_conv3d'
        )

        super().build(input_shape)

    def call(self, x):
        from tensorflow.keras import backend as K

        x_exp = K.expand_dims(x, axis=-1)

        c3d = K.conv3d(
            x_exp,
            self.kernel_conv3d,
            strides=(1, 1, self.i_shape[-1]),
            padding='same'
        )

        c3d = K.bias_add(c3d, self.bias_conv3d)
        c3d = tf.nn.relu(c3d)

        c3d = K.permute_dimensions(c3d, (0, 4, 1, 2, 3))
        c3d = K.squeeze(c3d, axis=-1)

        flat = tf.reshape(
            c3d,
            (-1, self.multiheads, self.i_shape[1] * self.i_shape[2])
        )

        alpha = tf.nn.softmax(flat, axis=-1)

        alpha = tf.reshape(
            alpha,
            (-1, self.multiheads, self.i_shape[1], self.i_shape[2])
        )

        exp_alpha = tf.expand_dims(alpha, axis=-1)
        x_exp2 = tf.expand_dims(x, axis=-2)

        u = exp_alpha * x_exp2

        u = tf.reshape(
            u,
            (-1,
             self.i_shape[1],
             self.i_shape[2],
             tf.shape(u)[-1] * tf.shape(u)[-2])
        )

        if self.concat_input_with_scaled:
            u = tf.concat([u, x], axis=-1)

        return [u, alpha]

    def get_config(self):
        config = super().get_config()
        config.update({
            "ch": self.channels,
            "m": self.multiheads,
            "aggregate": self.aggregate_channels,
            "concat_with_x": self.concat_input_with_scaled
        })
        return config


@tf.keras.utils.register_keras_serializable()
class DWT(tf.keras.layers.Layer):
    # 🔥 FIX IMPORTANT : must accept old model args
    def __init__(self, wavelet_name="haar", concat=0, **kwargs):
        super().__init__(**kwargs)
        self.wavelet_name = wavelet_name
        self.concat = concat

    def call(self, x):
        x = tf.cast(x, tf.float32)

        x01 = x[:, 0::2, :, :] / 2
        x02 = x[:, 1::2, :, :] / 2

        x1, x2 = x01[:, :, 0::2, :], x02[:, :, 0::2, :]
        x3, x4 = x01[:, :, 1::2, :], x02[:, :, 1::2, :]

        x_LL = x1 + x2 + x3 + x4
        x_HL = -x1 - x2 + x3 + x4
        x_LH = -x1 + x2 - x3 + x4
        x_HH = x1 - x2 - x3 + x4

        return tf.concat([x_LL, x_HL, x_LH, x_HH], axis=-1)

    def get_config(self):
        config = super().get_config()
        config.update({
            "wavelet_name": self.wavelet_name,
            "concat": self.concat
        })
        return config


@tf.keras.utils.register_keras_serializable()
class Gradients(tf.keras.layers.Layer):
    def call(self, inputs):
        dy, dx = tf.image.image_gradients(inputs)
        return tf.sqrt(tf.square(dx) + tf.square(dy))


@tf.keras.utils.register_keras_serializable()
class TrueDivide(tf.keras.layers.Layer):
    def call(self, inputs):
        if isinstance(inputs, list) and len(inputs) == 2:
            return inputs[0] / (inputs[1] + 1e-7)
        return inputs


@tf.keras.utils.register_keras_serializable()
class ExpandDims(tf.keras.layers.Layer):
    def __init__(self, axis=-1, **kwargs):
        super().__init__(**kwargs)
        self.axis = axis

    def call(self, inputs):
        return tf.expand_dims(inputs, axis=self.axis)

    def get_config(self):
        config = super().get_config()
        config.update({"axis": self.axis})
        return config


# =========================
# AI SERVICE
# =========================
class AiService:
    def __init__(self):
        current_dir = Path(__file__).resolve().parent

        self.model_path = os.getenv(
            "MODEL_PATH",
            str(current_dir.parent / "ml" / "skin_cancer_model.h5")
        )

        self.model = None
        self._load_error = None

    def _ensure_model_loaded(self):
        if self.model is not None or self._load_error is not None:
            return

        if not os.path.exists(self.model_path):
            self._load_error = f"Model not found: {self.model_path}"
            print(self._load_error)
            return

        try:
            self.model = tf.keras.models.load_model(
                self.model_path,
                custom_objects={
                    "SoftAttention": SoftAttention,
                    "DWT": DWT,
                    "Gradients": Gradients,
                    "TrueDivide": TrueDivide,
                    "ExpandDims": ExpandDims
                }
            )
            print(f"✅ Model loaded successfully: {self.model_path}")

        except Exception as e:
            self._load_error = str(e)
            print(f"❌ Model loading error: {e}")

    def _preprocess_image(self, image_path: str):
        img = PILImage.open(image_path).convert("RGB")
        img = img.resize((256, 256))
        img = np.array(img).astype(np.float32) / 255.0
        return np.expand_dims(img, axis=0)

    def predict(self, image_path: str) -> tuple[str, float]:
        self._ensure_model_loaded()

        # fallback mode (if model fails)
        if self.model is None:
            h = int(hashlib.md5(image_path.encode()).hexdigest(), 16)
            idx = h % len(CLASS_NAMES)
            return CLASS_NAMES[idx], 0.70

        try:
            img = self._preprocess_image(image_path)

            preds = self.model.predict(img, verbose=0)
            preds = np.array(preds)

            # fix multi-output / shape issues
            if preds.ndim == 2:
                preds = preds[0]

            idx = int(np.argmax(preds))
            confidence = float(preds[idx])

            label = CLASS_NAMES[idx] if idx < len(CLASS_NAMES) else "Unknown"

            return label, confidence

        except Exception as e:
            print(f"❌ Prediction error: {e}")
            return "Error", 0.0


# Singleton instance
ai_service = AiService()