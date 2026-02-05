---
title: Alicloud RAM and STS Permissions
categories:
  - Alicloud
---

## Introduction

When calling cloud resources through OpenAPI interfaces (i.e., as an alternative to console operations), there are currently two approaches:

- Direct invocation using AK+SK: as long as the account associated with the AK has the relevant permissions, it can call the corresponding resources (authorization is divided into system policies and custom policies).
- Alicloud accounts (RAM users) / Alicloud services (ECS, etc.) / Identity providers (SSO) can assume a role to obtain temporary credentials for that role (by calling the AssumeRole API). Through these temporary credentials (with a configurable session duration), the temporary AK + temporary SK + temporary STS Token obtained via the STS API can be used to call the corresponding resources.

## Official Concepts

1. STS Concept

Alicloud STS (Security Token Service) is a temporary access permission management service provided by Alicloud. RAM provides two types of identities: RAM users and RAM roles. RAM roles do not have permanent identity credentials and can only obtain temporary identity credentials with customizable validity periods and access permissions through STS, known as Security Tokens (STS Token).

> [Alicloud Documentation](https://help.aliyun.com/document_detail/28756.html)

2. RAM Concept

- RAM User: An identity entity, an account or program that can access Alicloud resources. When creating one, you can choose between console login or AccessKey scenarios (calling APIs programmatically).
- **RAM Role**: A virtual user that grants authorization to trusted RAM entity accounts (issuing short-lived temporary access tokens based on STS tokens). After creating a role, an ARN descriptor is generated (the role descriptor: each RAM role has a unique value and follows the Alicloud ARN naming convention).
- RAM Permission Policy: A set of permissions described using simple Policy syntax (divided into system policies and custom policies). A permission policy is the actual fine-grained description of authorized resource sets, operation sets, and authorization conditions.

<!-- {% asset_img ram1.png %} -->

> There are three types when creating a RAM role:
>
> - **Alicloud Account**: Roles that RAM users are allowed to assume. The RAM user assuming the role can belong to their own Alicloud account or to another Alicloud account. This type of role is mainly used to solve cross-account access and temporary authorization problems.
> - **Alicloud Service**: Roles that cloud services are allowed to assume. This type of role is mainly used to authorize cloud services to perform resource operations on your behalf (services are further divided into two types):
>   - Normal Service Role: You need to customize the role name, select the trusted service, and customize the permission policy.
>   - Service-Linked Role: You only need to select the trusted cloud service; the cloud service comes with a preset role name and permission policy.
>   - There is not much difference between the two service role types. Service-linked roles have an additional preset configuration (service roles are generally used for cross-service calls within Alicloud, such as ECS granting/revoking RAM role functionality, RDS cloud service calling KMS role encryption, etc. -- authorizing one cloud product to call another).

<!-- {% asset_img ram2.png %} -->

> - **Identity Provider**: Roles that users under a trusted identity provider are allowed to assume. This type of role is mainly used to implement Single Sign-On (SSO) with Alicloud.
>
> **The most commonly used RAM role type is the Alicloud Account method (officially recommended by OSS)**
>
> - RAM Role Authorization Introduction: [https://help.aliyun.com/document_detail/116819.html](https://help.aliyun.com/document_detail/116819.html)
> - OSS officially recommends using the Alicloud Account method: [https://help.aliyun.com/document_detail/100624.html](https://help.aliyun.com/document_detail/100624.html)

## Creating an STS Role and Testing Custom OSS Authorization

1) Test Account Information
Account: devops_test@xxx.onaliyun.com
AK: xxxxx
SK: xxxxx
ARN: acs:ram::xxxxx:role/xxx-sts
OSS Bucket Name: oss-test
OSS Authorized Directory: dir111/dir111_secondline1/

2) Granting Authorization

- Create a RAM user (sub-account) and generate AK SK (this step is omitted)
- Add STS permissions to the test account

<!-- {% asset_img ram3.png %} -->

- Add a permission policy using custom policy authorization (OSS official example Policy: [https://help.aliyun.com/document_detail/266627.html](https://help.aliyun.com/document_detail/266627.html))

<!-- {% asset_img ram4.png %} -->

- Add a RAM role and authorize the Policy

<!-- {% asset_img ram5.png %} -->

<!-- {% asset_img ram6.png %} -->

3) Testing and Verification (when you cannot log in to the RAM account via the console to verify permissions, you can use ossutil or ossbrowser tools for verification)

- ossutil Usage: [https://help.aliyun.com/document_detail/50451.html](https://help.aliyun.com/document_detail/50451.html)

<!-- {% asset_img ram7.png %} -->

- ossbrowser Usage: [https://help.aliyun.com/document_detail/92268.html](https://help.aliyun.com/document_detail/92268.html)

4) After verifying that listing and other related permissions are correct, provide the ARN information to the development team

> Permission Flow:
>
> The client program/caller initiates role assumption. Before obtaining the actual role permissions, it needs to call the AssumeRole API to return STS credentials (calling the STS API requires the **AliyunSTSAssumeRoleAccess** permission, so the corresponding RAM account must be authorized with this system policy).
> The returned STS temporary credentials (temporary AK + temporary SK + temporary token) are used to call the relevant cloud resource APIs.
> When the client uses STS to make calls, two permission policy sets are verified (Note: the final permission is the intersection of these two policies):

> Whether the permission policy authorized to the role assumed by STS has permission for the corresponding cloud resources (system or custom Policy).
> The policy_text parameter value passed in during SDK/API calls, included when constructing the call request ([Alicloud Documentation](https://help.aliyun.com/document_detail/100624.html))

<!-- {% asset_img ram8.png %} -->

## Practical Requirements

1. Developer request: Need STS ARN information for a specific OSS bucket.

2. Required information:

- The specific directory to authorize in the OSS bucket (required)
- endpoint: The region of the OSS bucket (optional)
- bucket-name: The OSS bucket name (required)
- The RAM account used to call OSS (required)

3. Based on the provided information, create a RAM role, create a new Policy (pay attention to fine-grained OSS policies), authorize the policy to the RAM role, and finally provide the ARN descriptor of the newly created RAM role to the development team.
