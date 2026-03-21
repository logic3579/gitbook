---
description: TensorFlow
tags:
  - cncf/cnai
---

# TensorFlow

## Introduction

TensorFlow is an open-source machine learning platform developed by Google Brain. It provides a comprehensive ecosystem for building and deploying ML models across a range of platforms, from mobile devices to large-scale distributed systems. TensorFlow uses static computation graphs (with eager execution available since 2.x) and excels in production deployment scenarios through TensorFlow Serving, TensorFlow Lite, and TensorFlow.js.

## Key Features

- **Keras API**: High-level API for rapid model prototyping and training
- **TensorFlow Serving**: Production-grade model serving with gRPC and REST endpoints
- **TensorFlow Lite**: Optimized runtime for mobile and edge devices
- **TFX Pipelines**: End-to-end ML pipelines for production workflows
- **SavedModel Format**: Portable model serialization for cross-platform deployment
- **TensorBoard**: Built-in visualization toolkit for training metrics and model graphs
- **Distributed Strategy**: Flexible APIs for multi-GPU and multi-node training

## Core Concepts

### Model Building with Keras

```python
import tensorflow as tf

model = tf.keras.Sequential([
    tf.keras.layers.Dense(256, activation='relu', input_shape=(784,)),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(128, activation='relu'),
    tf.keras.layers.Dense(10, activation='softmax')
])

model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

model.fit(train_dataset, epochs=10, validation_data=val_dataset)
```

### SavedModel Export

```python
# Save model
model.save('/tmp/my_model')

# Load model
loaded_model = tf.keras.models.load_model('/tmp/my_model')
```

## TensorFlow Serving

TensorFlow Serving provides a production deployment solution with automatic model versioning:

```bash
# Pull TF Serving image
docker pull tensorflow/serving:latest

# Start serving a model
docker run -p 8501:8501 \
  --mount type=bind,source=/models/my_model,target=/models/my_model \
  -e MODEL_NAME=my_model \
  tensorflow/serving
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tf-serving
spec:
  replicas: 2
  selector:
    matchLabels:
      app: tf-serving
  template:
    metadata:
      labels:
        app: tf-serving
    spec:
      containers:
        - name: tf-serving
          image: tensorflow/serving:latest
          ports:
            - containerPort: 8501  # REST
            - containerPort: 8500  # gRPC
          args:
            - --model_name=my_model
            - --model_base_path=/models/my_model
          resources:
            limits:
              nvidia.com/gpu: 1
          volumeMounts:
            - name: model-volume
              mountPath: /models
      volumes:
        - name: model-volume
          persistentVolumeClaim:
            claimName: model-pvc
```

> Reference:
>
> 1. [Official Website](https://www.tensorflow.org/)
> 2. [Repository](https://github.com/tensorflow)
