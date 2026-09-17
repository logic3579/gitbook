---
description: gRPC protocol
tags:
  - cncf/orchestration
  - networking
---

# gRPC

## Introduction

gRPC is a high-performance, open-source RPC framework originally developed by Google. It uses Protocol Buffers (protobuf) as both its interface definition language and underlying message serialization format. gRPC supports bidirectional streaming and runs on HTTP/2, providing features like multiplexing, header compression, and flow control. It is widely used in microservice architectures and cloud-native systems.

## Key Features

- **Protocol Buffers**: Strongly-typed, language-neutral IDL with efficient binary serialization
- **HTTP/2 Transport**: Multiplexed streams, header compression, and bidirectional communication
- **Streaming**: Unary, server-streaming, client-streaming, and bidirectional-streaming RPCs
- **Multi-Language**: Code generation for Go, Java, Python, C++, Node.js, Rust, and more
- **Deadlines/Timeouts**: Built-in deadline propagation across service boundaries
- **Interceptors**: Middleware chain for authentication, logging, and tracing
- **Load Balancing**: Client-side and proxy-based load balancing support

## Service Definition

gRPC services are defined using `.proto` files:

```protobuf
syntax = "proto3";

package helloworld;

service Greeter {
  // Unary RPC
  rpc SayHello (HelloRequest) returns (HelloReply);

  // Server-streaming RPC
  rpc SayHelloStream (HelloRequest) returns (stream HelloReply);
}

message HelloRequest {
  string name = 1;
  int32 age = 2;
}

message HelloReply {
  string message = 1;
}
```

### Code Generation

```bash
# Install protoc compiler and Go plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Generate Go code
protoc --go_out=. --go-grpc_out=. helloworld.proto
```

## Usage Example (Go)

### Server

```go
package main

import (
    "context"
    "log"
    "net"

    "google.golang.org/grpc"
    pb "example.com/helloworld"
)

type server struct {
    pb.UnimplementedGreeterServer
}

func (s *server) SayHello(ctx context.Context, req *pb.HelloRequest) (*pb.HelloReply, error) {
    return &pb.HelloReply{Message: "Hello " + req.GetName()}, nil
}

func main() {
    lis, _ := net.Listen("tcp", ":50051")
    s := grpc.NewServer()
    pb.RegisterGreeterServer(s, &server{})
    log.Fatal(s.Serve(lis))
}
```

### Client

```go
conn, _ := grpc.Dial("localhost:50051", grpc.WithInsecure())
defer conn.Close()

client := pb.NewGreeterClient(conn)
resp, _ := client.SayHello(context.Background(), &pb.HelloRequest{Name: "World"})
log.Println(resp.GetMessage())
```

## gRPC in Kubernetes

gRPC services require HTTP/2-aware load balancing. Use headless services with client-side load balancing or a proxy like Envoy:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: grpc-service
spec:
  clusterIP: None  # Headless for client-side LB
  ports:
    - name: grpc
      port: 50051
      protocol: TCP
  selector:
    app: grpc-server
```

### Health Checking

gRPC defines a standard health checking protocol. Configure Kubernetes probes with `grpc` type (Kubernetes 1.24+):

```yaml
spec:
  containers:
    - name: grpc-server
      ports:
        - containerPort: 50051
      livenessProbe:
        grpc:
          port: 50051
        initialDelaySeconds: 10
      readinessProbe:
        grpc:
          port: 50051
        initialDelaySeconds: 5
```

> Reference:
>
> 1. [Official Website](https://grpc.io/)
> 2. [Repository](https://github.com/grpc/grpc)
