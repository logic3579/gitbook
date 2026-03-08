---
description: gitflow
---

# Git Flow

## Introduction

### 1. GitFlow Description
gitflow: A branch management strategy for versioning (essentially a wrapper around git)
- Common branches include master, develop, feature, release, hotfix (support branch is rarely used)
- master and develop are remote branches; feature, release, and hotfix are local branches.
  - Remote branches are those that need to be pushed to remote repositories such as GitLab or GitHub
  - Local branches refer to the git version control environment used by developers for local development


### 2. GitFlow Flowchart and Description
![image](https://github.com/logic3579/knowledge/assets/30774576/f4811bbc-3c1f-476d-9257-c8e0404aec17)
![image](https://github.com/logic3579/knowledge/assets/30774576/70fd63ab-8ad5-4234-8131-8b26b4067129)

- master: Main branch
![image](https://github.com/logic3579/knowledge/assets/30774576/e6745b38-ce61-410d-8b4c-4b1f31b6e7c6)

  - The most stable branch with complete functionality, ready to be released to production at any time (read-only branch, can only be merged from hotfix/release, cannot be directly modified)
  - Pushes to the master branch should be tagged for traceability;

- develop: Development branch
  - The branch with the latest and most complete features, cloned from master (only the first time);
  - Feature branches are merged into develop after passing local testing, then deleted;
  - After collecting all features to go live (containing all code to be released in the next release), a release branch is created from develop for testing;
  - After release/hotfix branches go live, they are merged into develop and pushed;

- feature: Feature development branch
![image](https://github.com/logic3579/knowledge/assets/30774576/1e012286-8b80-4351-95a4-a9995375078f)

  - For developing specific new features, cloned from the develop branch. After feature development is complete and local testing passes (compilation succeeds without errors), it is merged into the develop branch;
  - Multiple feature branches can exist simultaneously, i.e., multiple team members can create temporary branches for concurrent development. Branches can optionally be deleted after completion;

- release: Testing branch
![image](https://github.com/logic3579/knowledge/assets/30774576/c5b01f4a-8246-4815-9ec3-e9c07324e2bd)

  - Used for submitting to testers for functional testing, cloned from the develop branch after feature branches have been merged into develop;
  - Bugs found during testing are fixed on this branch by creating bugfix-* branches. After all bugs are fixed and the release goes live, it is merged into both develop/master and pushed (completing the feature). A tag is created when pushing to master;
  - Temporary branch, can optionally be deleted after going live (once release testing begins, new features from develop are not allowed to be merged into the release branch; new features must wait for the next release cycle);

- hotfix: Patch branch
![image](https://github.com/logic3579/knowledge/assets/30774576/68e94074-3fed-4320-8c28-705edaf80b46)

  - Cloned from the master branch, primarily used for fixing bugs in the production version;
  - After fixing bugs, merged into develop/master and pushed (all hotfix changes will be included in the next release). A tag is created when pushing to master;
  - Temporary branch, can optionally be deleted after the bug is fixed

### 3. Development Guidelines and Conventions
- Guidelines
  - Apart from source code, any build artifacts (e.g., Maven's target folder, .idea folder, etc.) must not be committed to the source repository and should be added to the .gitignore file
  - Developers must strictly follow the agreed-upon gitflow branch management process, switching to the designated branch for developing the corresponding features
  - After completing a task, thorough self-testing based on test cases must be performed before pushing to develop. It is strictly prohibited to push code that fails compilation or is incomplete to remote branches
- Conventions:
  - Main branch name: master; Main development branch: develop
  - Tag name: v*.release, where "*" is the version number, "release" is lowercase, e.g., v1.0.0.release
  - Feature development branch name: feature-*, where "*" is the corresponding task number from Jira (Aone)
  - Release branch name: release-*, where "*" is the version number, "release" is lowercase, e.g., release-1.0.0. Bug fix branches on the release branch are named bugfix-*
  - Bug fix branch for master: hotfix-*, where "*" is the corresponding task number from Jira (Aone)

## Testing Section

- Local git flow init to initialize the repository, push the develop branch
![image](https://github.com/logic3579/knowledge/assets/30774576/6de0f321-ff9f-4d54-b71d-88b01839794e)
![image](https://github.com/logic3579/knowledge/assets/30774576/4b5defef-974e-4663-94f2-092dde3c3f82)


- Push to the remote test GitHub repository (using SSH public key authentication). The develop branch now has its first commit
![image](https://github.com/logic3579/knowledge/assets/30774576/758592c7-5690-4751-bae0-8a79e7d9cc1f)


- Create a new working directory under tmp and clone the remote repository locally (simulating a developer's local development environment)
![image](https://github.com/logic3579/knowledge/assets/30774576/5d0687f9-b737-4a14-a7c0-20731f5896f4)

- After initializing the repository, pull the develop branch locally for development. At this point, you can create a feature branch for feature development
![image](https://github.com/logic3579/knowledge/assets/30774576/47244919-fa8b-4542-884a-f3d20c5fe8ef)
![image](https://github.com/logic3579/knowledge/assets/30774576/aa41d1a7-04f7-4b6c-8bb6-d1d899844513)


- After committing the feature development, push to the remote repository and track the remote branch. Subsequent changes can be continuously pushed with git push
![image](https://github.com/logic3579/knowledge/assets/30774576/5e7ac235-dafe-4d9b-9783-155f9c1c1a69)
![image](https://github.com/logic3579/knowledge/assets/30774576/f30c3c26-7597-4789-a85d-f3206cc96880)


- After feature development is complete, merge the branch into develop and delete the local feature branch (adding the -F flag will also delete the remote branch)
![image](https://github.com/logic3579/knowledge/assets/30774576/243b61f3-4e4a-4907-9e24-e4247aafcad1)

After the finish command, the new feature is merged into the develop branch, completing the new feature development. The subsequent release publishing operation follows similar steps



> Reference:
> 1. [Learn Website](https://www.gitkraken.com/learn/git/git-flow)