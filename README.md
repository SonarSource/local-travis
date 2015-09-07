# Travis CI

Our projects use [Travis CI][travis] to run their continuous integration.
The status of all the open-source projects on Travis can be seen here:
 + https://travis-ci.org/SonarSource for [SonarSource][sonarsource] projects
 + https://travis-ci.org/SonarCommunity for [SonarCommunity][sonarcommunity] projects.

## Configuring a project on Travis CI

To enable Travis on a given project, follow [these instructions][enable].

Basically, you have to add a `.travis.yaml` file to the project,
then configure Travis CI to build every push/branch/pr on that project.

Here's a sample `.travis.yaml` that builds a java project and runs its tests
using maven.

```yaml
language: java
sudo: false
jdk: oraclejdk7
install: true
script: mvn verify -B -e -V
cache:
  directories:
    - '$HOME/.m2/repository'
```

## Test Matrix

Some project need to run multiple sets of tests, such as unit tests and
integration tests. Let's call it a test matrix.

The approach we choose for SonarSource projects, is to describe the set of
commands for each category of tests in a `travis.sh` file at the root of the
project and have travis run that script with different set of parameters, passed
as environment variables.

*travis.sh*

```bash
#!/bin/bash

set -euo pipefail

case "$JOB" in
CI)
  mvn verify -B -e -V
  ;;
ITS)
  # Setup something before (database, files...)
  mvn verify -Pit -Dcategory=$IT_CATEGORY
  ;;
esac
```

*.travis.yml*

```yaml
language: java
sudo: false
jdk: oraclejdk7
install: true
script: ./travis.sh

env:
  - JOB=CI
  - JOB=ITS IT_CATEGORY=issue
  - JOB=ITS IT_CATEGORY=analysis

cache:
  directories:
    - '$HOME/.m2/repository'
```

## Integration tests

Integration tests sometimes have to setup their environment before the tests
are actually run. For example with most SonarQube, we have to either download
the latests release of SonarQube or build the latest development version.

Because each build run on a fresh *server* on Travis CI, tests can install
whatever they need without fear of creating site effects for other builds.
That makes it very easy to run ITs on Travis but could make it difficult
to run tests on a developer workstation to debug a failure.

You can use [Docker][docker] to run more our build scripts on your machine.

## Run a build with Docker

Here are the steps to follow to run a build with Docker:

 1. [Install Docker][install]
 2. Create a `Dockerfile` file at the root of the project.
    The file will, most of the time, be as simple as:

    ```Dockerfile
    FROM dgageot/travis-docker
    ```

 3. Build the docker image. The image will then contain both your sources and
    the whole environment needed to run the tests. (Each time you change the
    sources, you have to re-build the image. First time will be long because
    Docker needs to download the base image. Then it will be very quick.)

    ```bash
    docker build -t ci .
    ```

 4. Run the build. Most of the time it means running `travis.sh` command with
    the right set of environment variables.

    ```bash
    docker run -ti -e JOB=CI ci ./travis.sh
    # or
    docker run -ti -e JOB=IT-DEV ci ./travis.sh
    ```

 5. If the build is not green, you might want to explore the artefacts left
    after the build. With Docker, it's something common to re-enter a stopped
    container to analyse what failed. You just have to find the id of that
    container that just stopped.

    ```
    docker ps -a

    CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                        PORTS               NAMES
    67ac1c89e8cc        ci                  "./travis.sh"       23 minutes ago      Exited (130) 1 minutes ago                       lonely_shockley

    # Re-enter that container with bash
    docker --rm -ti exec [CONTAINER ID] bash
    ```

  An easier way of doing this, for beginners, is to start the container with `bash` command instead of `./travis.sh`.
  This way, you can run `./travis.sh` inside the container and at the end of the build you'll still be inside the container, ready to list and view build output.

  ```
  docker run -ti -e JOB=CI ci bash
  ./travis.sh
  ls target
  exit
  ```

 6. Fix some code
 7. Goto 3. The container needs to be rebuilt before a new run is started.

## Accelerate the build

Because the build runs in a blank container, each time it runs, it needs to download
all the maven dependencies (You know that "Maven downloads the Internet" thing).
One way of fixing that is to share your own `.m2` repository with the container:

```bash
docker run -ti -v $HOME/.m2/:/root/.m2/ -e JOB=CI ci ./travis.sh
```

This is **good** because the build will be faster and use less bandwidth.
This is **bad** because you might have something in that repository that shouldn't
be here, a SNAPSHOT dependency for example, and the build might pass on
your machine and fail on Travis.

[travis]: https://travis-ci.org/
[travis-sonarsource]: https://travis-ci.org/SonarSource
[sonarsource]: https://github.com/SonarSource
[travis-sonarcommunity]: https://travis-ci.org/SonarCommunity
[sonarcommunity]: https://github.com/SonarCommunity
[enable]: http://docs.travis-ci.com/user/getting-started/
[docker]: https://www.docker.com/
[install]: https://docs.docker.com/
