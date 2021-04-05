# deploy simple flatcar vm

## vm

simple flatcat vm deploy template.

```sh
make make RESOURCE_GROUP=your-rg deploy
```

### note

This template includes some useful features for flatcat VM.

1. Opened ssh NSG port from only deployed address.
2. Generate a new ssh key for deployed VM. see: ./.secure/vm-keys and .pub.
3. VM login account set up in config.yml. If you use this template that should be changed.
4. You can deploy this template from VS Code dev containers terminal.

## vm-loganalytics

flatcat vm, log analytics and container solution deploy template.

```sh
make make RESOURCE_GROUP=your-rg deploy
```

### deploy oms agent container

deploy oms agent container on remote host.

```sh
DOCKER_HOST="ssh://$(cat ./.secure/deploy-results.json | jp -u hostname.value)"
WSID="$(cat ./.secure/deploy-results.json | jp -u workspaceId.value)"
WSKEY="$(cat ./.secure/deploy-results.json | jp -u workspaceKey.value)"

docker run --rm busybox echo hello; echo world
docker run --privileged -d -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/containers:/var/lib/docker/containers -e WSID=$WSID -e KEY=$WSKEY -h=`hostname` -p 127.0.0.1:25225:25225 --name="omsagent" --restart=always microsoft/oms
```

## vmss

deploy flatcar vmss and bootstrap etcd cluster.

```sh
make make RESOURCE_GROUP=your-rg deploy
```

## License

Copyright (c) Takekazu Omi. All rights reserved.
Licensed under the MIT License. See [LICENSE](https://github.com/Microsoft/vscode-dev-containers/blob/master/LICENSE).
