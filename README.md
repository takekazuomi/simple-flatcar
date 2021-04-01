# deploy simple flatcar vm

simple flatcat vm deploy template

```sh
make make RESOURCE_GROUP=your-rg deploy
```

## note

This template includes some useful features for flatcat VM.

1. Opened ssh NSG port from only deployed address.
2. Generate a new ssh key for deployed VM. see: ./.secure/vm-keys and .pub.
3. VM login account set up in config.yml. If you use this template that should be changed.
4. You can deploy this template from VS Code dev containers terminal.

## License

Copyright (c) Takekazu Omi. All rights reserved.
Licensed under the MIT License. See [LICENSE](https://github.com/Microsoft/vscode-dev-containers/blob/master/LICENSE).
