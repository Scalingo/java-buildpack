Buildpack: Java
=======

This is a [Buildpack](https://doc.scalingo.com/buildpacks) for Java apps.
It uses Maven 3.3.9 to build your application and OpenJDK 8 to run it. However, the JDK version can be configured as described below.

## How it works

The buildpack will detect your app as Java if it has a `pom.xml` file, or one of the other POM formats supports by the [Maven Polyglot](https://github.com/takari/polyglot-maven) plugin, in its root directory.  It will use Maven to execute the build defined by your `pom.xml` and download your dependencies. The `.m2` folder (local maven repository) will be cached between builds for faster dependency resolution. However neither the mvn executable or the .m2 folder will be available in your slug at runtime.

```
  $ ls
  Procfile  pom.xml  src

  $ scalingo create java-app

  $ git push scalingo master
  ...
  -----> Java app detected
  -----> Installing OpenJDK 1.8... done
  -----> Installing Maven 3.2.5... done
  -----> Installing settings.xml... done
  -----> executing /app/tmp/repo.git/.cache/.maven/bin/mvn -B -Duser.home=/tmp/build_19z6l4hp57wqm -Dmaven.repo.local=/app/tmp/repo.git/.cache/.m2/repository -s /app/tmp/repo.git/.cache/.m2/settings.xml -DskipTests=true clean install
         [INFO] Scanning for projects...
         [INFO]
         [INFO] ------------------------------------------------------------------------
         [INFO] Building readmeTest 1.0-SNAPSHOT
         [INFO] ------------------------------------------------------------------------
```

## Examples

* [Tomcat Webapp-Runner Example](https://github.com/kissaten/webapp-runner-minimal)

## Configuration

### Choose a JDK

Create a `system.properties` file in the root of your project directory and set `java.runtime.version=1.8`.

Example:

    $ ls
    Procfile pom.xml src

    $ echo "java.runtime.version=1.8" > system.properties

    $ git add system.properties && git commit -m "Java 8"

    $ git push scalingo master
    ...
    -----> Java app detected
    -----> Installing OpenJDK 1.8... done
    -----> Installing Maven 3.3.9... done
    ...

### Choose a Maven Version

You can define a specific version of Maven for Scalingo to use by adding the
[Maven Wrapper](https://github.com/takari/maven-wrapper) to your project. When
this buildpack detects the precense of a `mvnw` script and a `.mvn` directory,
it will run the Maven Wrapper instead of the default `mvn` command.

If you need to override this, the `system.properties` file also allows for a `maven.version` entry
(regardless of whether you specify a `java.runtime.version` entry). For example:

```
java.runtime.version=1.8
maven.version=3.3.9
```

### Customize Maven

There are three config variables that can be used to customize the Maven execution:

+ `MAVEN_CUSTOM_GOALS`: set to `clean dependency:list install` by default
+ `MAVEN_CUSTOM_OPTS`: set to `-DskipTests` by default
+ `MAVEN_JAVA_OPTS`: set to `-Xmx1024m` by default

These variables can be set like this:

```sh-session
$ scalingo env-set MAVEN_CUSTOM_GOALS="clean package"
$ scalingo env-unset MAVEN_CUSTOM_OPTS="--update-snapshots -DskipTests=true"
$ scalingo env-set MAVEN_JAVA_OPTS="-Xss2g"
```

## Development

To make changes to this buildpack, fork it on Github. Push up changes to your fork, then create a new Scalingo app to test it, or configure an existing app to use your buildpack:

```
# Create a new Scalingo app that uses your buildpack
scalingo create new-app

# Configure an existing Scalingo app to use your buildpack
scalingo env-set GITHUB_URL=<your-github-url>

# You can also use a git branch!
scalingo env-set GITHUB_URL=<your-github-url>#your-branch
```

For example if you want to have maven available to use at runtime in your application, you can copy it from the cache directory to the build directory by adding the following lines to the compile script:

    for DIR in ".m2" ".maven" ; do
      cp -r $CACHE_DIR/$DIR $BUILD_DIR/$DIR
    done

This will copy the local maven repo and maven binaries into your slug.

Commit and push the changes to your buildpack to your Github fork, then push your sample app to Scalingo to test. Once the push succeeds you should be able to run:

    $ scalingo run bash

and then:

    $ ls -al

and you'll see the `.m2` and `.maven` directories are now present in your slug.

License
-------

Licensed under the MIT License. See LICENSE file.
