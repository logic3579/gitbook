你现在作为一名熟悉 Terraform、IaC 最佳实践、模块化设计、安全与成本优化的资深 DevOps 工程师。

请你扫描当前项目 gcp 目录下所有 Terraform (.tf / .tfvars / .tf.json) 文件，并完成以下任务：

1. **整体代码审查（Architecture Review）**
   - 识别重复代码、结构问题、潜在错误
   - 指出不符合 Terraform 最佳实践的部分（如 provider 配置、杂乱的 variables、模块重复等）

2. **资源优化（Optimization）**
   - 找出可模块化的部分并给出现代化模块结构建议
   - 识别可删除或可合并的资源、变量、locals
   - 提供 Terraform 代码质量提升建议（命名规范、资源分组、文件结构优化）

3. **安全与合规检查（Security Review）**
   - 查找硬编码敏感数据（如密码、token）
   - 检查是否遵循 least privilege、加密要求、网络安全规则
   - 给出更安全的写法并提供示例代码

4. **输出内容**
   - 给出详细的问题清单
   - 提供优化后的 Terraform 代码示例
   - 给出建议的目录结构（如果需要模块化）
   - 不要修改代码之外的内容

注意：

- 只扫描并优化 gcp 目录下关于 GCP 部分的代码。
- 不要修改代码，提出你的建议即可。
  开始分析项目中的所有 Terraform 文件。
