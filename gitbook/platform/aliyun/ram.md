---
description: Aliyun RAM and STS permission management, role-based access control, and temporary credential workflow
tags:
  - platform/aliyun
  - security
---

# RAM

Aliyun RAM provides identity and access management; STS issues short-lived credentials via AssumeRole for cross-account access and service-to-service authorization.

## Authentication Methods

When calling cloud resources through OpenAPI (i.e., as an alternative to console operations), there are two approaches:

- **Direct invocation using AK+SK**: as long as the account associated with the AK has the relevant permissions, it can call the corresponding resources (authorization is divided into system policies and custom policies).
- **AssumeRole + STS**: Aliyun accounts (RAM users) / Aliyun services (ECS, etc.) / Identity providers (SSO) can assume a role to obtain temporary credentials (by calling the AssumeRole API). The temporary AK + temporary SK + STS Token (with a configurable session duration) are then used to call the corresponding resources.

## Concepts

1. **STS** (Security Token Service) — Aliyun STS is a temporary access permission management service. RAM provides two identity types: RAM users and RAM roles. RAM roles do not have permanent identity credentials and can only obtain temporary identity credentials with customizable validity periods and access permissions through STS, known as Security Tokens (STS Token).

   > [Aliyun Documentation](https://help.aliyun.com/document_detail/28756.html)

2. **RAM User** — An identity entity (account or program) that can access Aliyun resources. When creating one, you can choose between console login or AccessKey scenarios (calling APIs programmatically).

3. **RAM Role** — A virtual user that grants authorization to trusted RAM entity accounts (issuing short-lived temporary access tokens based on STS tokens). After creating a role, an ARN descriptor is generated (the role descriptor: each RAM role has a unique value and follows the Aliyun ARN naming convention).

4. **RAM Permission Policy** — A set of permissions described using simple Policy syntax (divided into system policies and custom policies). A permission policy is the actual fine-grained description of authorized resource sets, operation sets, and authorization conditions.

There are three types when creating a RAM role:

- **Aliyun Account**: Roles that RAM users are allowed to assume. The RAM user can belong to your own account or another Aliyun account. Mainly used for cross-account access and temporary authorization. **Officially recommended by OSS**.
- **Aliyun Service**: Roles that cloud services are allowed to assume. Mainly used to authorize cloud services to perform resource operations on your behalf:
  - **Normal Service Role**: Customize the role name, select the trusted service, and customize the permission policy.
  - **Service-Linked Role**: Select the trusted cloud service; the cloud service comes with a preset role name and permission policy.
- **Identity Provider**: Roles that users under a trusted identity provider are allowed to assume. Mainly used for SSO with Aliyun.

> - RAM Role Authorization: [https://help.aliyun.com/document_detail/116819.html](https://help.aliyun.com/document_detail/116819.html)
> - OSS recommended Aliyun Account method: [https://help.aliyun.com/document_detail/100624.html](https://help.aliyun.com/document_detail/100624.html)

## STS Workflow

Example: creating an STS role for custom OSS authorization.

1. **Test account information**

   ```text
   Account: devops_test@xxx.onaliyun.com
   AK: xxxxx
   SK: xxxxx
   ARN: acs:ram::xxxxx:role/xxx-sts
   OSS Bucket Name: oss-test
   OSS Authorized Directory: dir111/dir111_secondline1/
   ```

2. **Granting authorization**

   - Create a RAM user (sub-account) and generate AK / SK.
   - Add STS permissions to the test account.
   - Add a permission policy using custom policy authorization. ([OSS official example Policy](https://help.aliyun.com/document_detail/266627.html))
   - Add a RAM role and attach the policy.

3. **Testing and verification** (when you cannot log in to the RAM account via the console to verify permissions, use ossutil or ossbrowser):

   - [ossutil usage](https://help.aliyun.com/document_detail/50451.html)
   - [ossbrowser usage](https://help.aliyun.com/document_detail/92268.html)

4. After verifying list/read/write permissions, provide the ARN information to the development team.

**Permission flow**:

The client program/caller initiates role assumption. Before obtaining the actual role permissions, it calls the AssumeRole API to return STS credentials (this call requires the **AliyunSTSAssumeRoleAccess** permission, so the calling RAM account must be authorized with this system policy). The returned STS temporary credentials (temporary AK + temporary SK + temporary token) are then used to call the relevant cloud resource APIs.

When the client uses STS to make calls, two permission policy sets are verified — the final permission is the **intersection** of:

- The permission policy attached to the role assumed by STS (system or custom Policy).
- The `policy_text` parameter passed in during SDK/API calls. ([Aliyun Documentation](https://help.aliyun.com/document_detail/100624.html))

## Practical Requirements

1. **Developer request**: Need STS ARN information for a specific OSS bucket.

2. **Required information from developer**:
   - The specific directory to authorize in the OSS bucket (required)
   - endpoint: The region of the OSS bucket (optional)
   - bucket-name: The OSS bucket name (required)
   - The RAM account used to call OSS (required)

3. Based on the provided information, create a RAM role, create a new Policy (pay attention to fine-grained OSS policies), attach the policy to the RAM role, and provide the ARN descriptor to the development team.

## CLI

### Users

```bash
aliyun ram CreateUser --UserName test-user --DisplayName "Test User"
aliyun ram ListUsers
aliyun ram GetUser --UserName test-user
aliyun ram UpdateUser --UserName test-user --NewDisplayName "Renamed"
aliyun ram DeleteUser --UserName test-user
```

### Access Keys

```bash
aliyun ram CreateAccessKey --UserName test-user
aliyun ram ListAccessKeys --UserName test-user
aliyun ram UpdateAccessKey --UserName test-user --UserAccessKeyId AK --Status Inactive
aliyun ram DeleteAccessKey --UserName test-user --UserAccessKeyId AK
```

### Roles

```bash
# trust.json defines who can assume the role
aliyun ram CreateRole \
  --RoleName test-role \
  --AssumeRolePolicyDocument "$(cat trust.json)"
aliyun ram ListRoles
aliyun ram GetRole --RoleName test-role
aliyun ram UpdateRole \
  --RoleName test-role \
  --NewAssumeRolePolicyDocument "$(cat trust.json)"
aliyun ram DeleteRole --RoleName test-role
```

### Policies

```bash
aliyun ram CreatePolicy \
  --PolicyName test-policy \
  --PolicyDocument "$(cat policy.json)"
aliyun ram ListPolicies
aliyun ram GetPolicy --PolicyType Custom --PolicyName test-policy
aliyun ram DeletePolicy --PolicyName test-policy
```

### Policy Attachments

```bash
# Attach to user
aliyun ram AttachPolicyToUser \
  --PolicyType Custom --PolicyName test-policy --UserName test-user
aliyun ram DetachPolicyFromUser \
  --PolicyType Custom --PolicyName test-policy --UserName test-user

# Attach to role
aliyun ram AttachPolicyToRole \
  --PolicyType Custom --PolicyName test-policy --RoleName test-role
aliyun ram DetachPolicyFromRole \
  --PolicyType Custom --PolicyName test-policy --RoleName test-role

# List bindings
aliyun ram ListPoliciesForUser --UserName test-user
aliyun ram ListPoliciesForRole --RoleName test-role
```

### AssumeRole (STS)

```bash
aliyun sts AssumeRole \
  --RoleArn acs:ram::ACCOUNT_ID:role/test-role \
  --RoleSessionName test-session \
  --DurationSeconds 3600

# With session policy to further narrow permissions (intersection)
aliyun sts AssumeRole \
  --RoleArn acs:ram::ACCOUNT_ID:role/test-role \
  --RoleSessionName test-session \
  --DurationSeconds 3600 \
  --Policy "$(cat session-policy.json)"
```

> Reference:
>
> 1. [RAM Documentation](https://help.aliyun.com/product/28625.html)
> 2. [STS Documentation](https://help.aliyun.com/document_detail/28756.html)
