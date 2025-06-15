---
description: ACK Monitoring
---

# ACK Monitoring

## 一、背景
- 线上ACK 集群部署了StatefulSet 应用（rabbitMQ），由于rabbitMQ 本身自带的management 后台数据展示较为简陋且没有告警功能，因此考虑接入云上产品监控资源数据且对接告警通知功能，主要通过如下产品实现：
   - 接入Prometheus 监控+grafana 进行数据图表展示。
   - 利用Arms 产品获取Prometheus 的监控指标，按照设定的阈值进行告警通知功能。

## 二、操作过程
### 1）接入Prometheus 组件监控，获取数据指标

- 进入云产品 **Prometheus监控服务**，选择对应集群。（ACK集群需要先安装Prometheus 监控组件，安装参考：[ARMS Prometheus监控](https://help.aliyun.com/document_detail/161304.html)）
![image](https://github.com/yakir3/knowledge/assets/30774576/ce49db98-2a2f-4c8d-a751-f20ecb9c2474)


- 选择 组件监控 ，点击添加组件监控，选择要添加的组件。（本次示例为RabbitMQ）
![image](https://github.com/yakir3/knowledge/assets/30774576/813a9009-e886-406d-ac34-35dd85f5b1e0)
![image](https://github.com/yakir3/knowledge/assets/30774576/ee2c6fda-e9fc-47da-a99e-d1707223c9b6)

- 添加后即可进入grafana 大盘查看指标数据。验证数据方式可以通过 **curl  xxx:9419/metrics ** 获取指标数据，如图:
![image](https://github.com/yakir3/knowledge/assets/30774576/f1b5ad66-55f9-4a93-bcb4-fe7bdffdedcc)


### 2）grafana 接入数据展示

- 从Pometheus 控制台，点击对应生成的大盘，进入grafana 数据展示界面
![image](https://github.com/yakir3/knowledge/assets/30774576/a27e3370-9514-4aa2-8054-1c17cc98fc35)

- 进入grafana Dashboard界面后，需要新增一个panel。操作如下：
![image](https://github.com/yakir3/knowledge/assets/30774576/1e9b76f4-e4ae-4b48-9e28-1419add8b722)
![image](https://github.com/yakir3/knowledge/assets/30774576/da76aa68-16a4-47d8-806a-f8e22d0d8ec2)
![image](https://github.com/yakir3/knowledge/assets/30774576/9bab624d-6e04-4090-84db-0c476d45083e)

- 在ACK集群查看展示组件相关监控数据：在对应ACK 集群中，选择 **运维管理 -- Prometheus监控 --Cloud RABBITMQ** ，即可查看大盘数据。
![image](https://github.com/yakir3/knowledge/assets/30774576/783c785f-d7e3-4c76-ada9-a86ad8f2bfef)

### 3）创建告警阈值与通知

- 创建钉钉群，并生成钉钉机器人webhook地址。参考：[https://help.aliyun.com/document_detail/251838.html](https://help.aliyun.com/document_detail/251838.html)

- 在云产品 **Prometheus监控服务** 中，将钉钉机器人添加到告警联系人，使用IM机器人方式。
![image](https://github.com/yakir3/knowledge/assets/30774576/839015bd-8f52-4b80-9921-95d76e112a20)

- 在云产品 **应用实时监控服务ARMS -- Prometheus监控 -- Prometheus告警规则** 中，点击**创建Prometheus告警规则** ，创建告警规则。告警规则详细如图：
![image](https://github.com/yakir3/knowledge/assets/30774576/c18ff441-b85b-4ef9-b4b8-4cba00f6140a)
![image](https://github.com/yakir3/knowledge/assets/30774576/280251b2-8d76-40dd-a9c5-58acfd58ad70)

- 在云产品 **应用实时监控服务ARMS -- 告警管理 -- 通知策略** 中，点击**创建通知策略** ，创建告警通知策略。策略配置详细如图：
![image](https://github.com/yakir3/knowledge/assets/30774576/7b294469-b708-4e43-9790-ac6e37754b99)
![image](https://github.com/yakir3/knowledge/assets/30774576/215729d6-a0f7-461c-9c68-7add6208148d)

### 4）验证告警

- 将告警规则中PromQL 语句暂时配置为：sum by (queue)(rabbitmq_queue_messages_unacknowledged{app="rabbi-exporter"}) >= 0

来产生告警

- 在云产品 **应用实时监控服务ARMS -- 告警管理 -- 告警发送历史/告警事件历史** 中，搜索告警事件与发送结果：
![image](https://github.com/yakir3/knowledge/assets/30774576/a61fec82-a752-4859-9d65-b2d26c870b9c)
![image](https://github.com/yakir3/knowledge/assets/30774576/2edb7be7-2f47-4991-b199-c67d01a25b59)

- 可以看到钉钉群已正常接收告警通知（告警恢复自动发送恢复通知并停止发送告警消息）
![image](https://github.com/yakir3/knowledge/assets/30774576/5886ee87-351c-496a-a701-9e2c056848fb)

## 三、注意事项

- ACK 集群 RabbitMQ应用告警是创建的临时告警群。后续如需添加其他人或告警通知发布到正式群组按情况进行调整。
