---
description: PyTorch
tags:
  - cncf/cnai
---

# PyTorch

## Introduction

PyTorch is an open-source machine learning framework developed by Meta AI, widely used for deep learning research and production deployment. It provides a flexible, imperative programming model with dynamic computation graphs (eager execution), making it intuitive for Python developers. PyTorch has become the dominant framework in academic research and is increasingly adopted for production workloads through TorchServe and ONNX export.

## Key Features

- **Dynamic Computation Graphs**: Define-by-run approach allows modifying the graph on the fly, simplifying debugging and experimentation
- **GPU Acceleration**: Native CUDA support with seamless CPU/GPU tensor operations
- **Autograd**: Automatic differentiation engine that powers neural network training
- **TorchScript**: JIT compiler for optimizing and serializing models for production
- **Distributed Training**: Built-in support for data-parallel and model-parallel training across multiple GPUs and nodes
- **Rich Ecosystem**: torchvision, torchaudio, torchtext, and HuggingFace integration

## Core Concepts

### Tensors

Tensors are the fundamental data structure, similar to NumPy arrays but with GPU acceleration:

```python
import torch

# Create tensors
x = torch.tensor([1.0, 2.0, 3.0])
y = torch.randn(3, 4, device='cuda')  # directly on GPU

# Operations
z = torch.matmul(y.T, y)
```

### Model Definition

```python
import torch.nn as nn

class SimpleNet(nn.Module):
    def __init__(self, input_dim, hidden_dim, output_dim):
        super().__init__()
        self.fc1 = nn.Linear(input_dim, hidden_dim)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_dim, output_dim)

    def forward(self, x):
        return self.fc2(self.relu(self.fc1(x)))

model = SimpleNet(784, 256, 10).cuda()
```

### Training Loop

```python
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)
criterion = nn.CrossEntropyLoss()

for epoch in range(num_epochs):
    for inputs, labels in dataloader:
        inputs, labels = inputs.cuda(), labels.cuda()
        optimizer.zero_grad()
        outputs = model(inputs)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
```

## Kubernetes Integration

PyTorch distributed training can run on Kubernetes using the Kubeflow PyTorchJob operator:

```yaml
apiVersion: kubeflow.org/v1
kind: PyTorchJob
metadata:
  name: pytorch-training
spec:
  pytorchReplicaSpecs:
    Master:
      replicas: 1
      template:
        spec:
          containers:
            - name: pytorch
              image: pytorch/pytorch:2.2.0-cuda12.1-cudnn8-runtime
              resources:
                limits:
                  nvidia.com/gpu: 1
    Worker:
      replicas: 3
      template:
        spec:
          containers:
            - name: pytorch
              image: pytorch/pytorch:2.2.0-cuda12.1-cudnn8-runtime
              resources:
                limits:
                  nvidia.com/gpu: 1
```

> Reference:
>
> 1. [Official Website](https://pytorch.org/)
> 2. [Repository](https://github.com/pytorch/pytorch)
