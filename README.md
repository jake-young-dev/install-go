# install-go
An extremely simple github action to install golang and golang commands (using "go install") on linux hosts. This provides the ability to install and setup golang without node/typescript which is required when using [actions/setup-go](https://github.com/actions/setup-go). 


## Usage
Use a tagged release to avoid unexpected changes that may come to the main branch
```yaml
    name: "install go"
    uses: https://github.com/jake-young-dev/install-go@main
    with:
        commands: |
            github.com/itchyny/gojq/cmd/gojq@latest
```

#### Go verions
The go version installed is either determined by the version input, or the version found in a go.mod file if the input is not set. Go files are pulled directly from the Go download [site](https://go.dev/dl/) and all go commands are installed using 'go install' after setup. If a different version of Go is already installed the 'purge' input must be set to 'yes' to remove it and avoid errors.

#### Inputs
Some inputs are available to customize the installation
|Input|Required|Values|Default|Description|
|---|---|---|---|---|
|arch|no|any arch for Go|amd64|system architecture for go
|purge|no|yes/no|no|remove any go files found on system before install
|commands|no|any public go repositories|.|links to any commands to be installed using 'go install'
|version|no|any go version|version in go.mod file|the go version to install

## Issues
This repo is a as brain-dead as I could make it and is intended to be as fast and low-level as possible. Please open an issue for any problems or suggestions.
