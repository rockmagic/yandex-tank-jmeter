Latest versions of [Yandex Tank](https://github.com/yandex/yandex-tank) and Apache Jmeter

## Usage

In order to provide SSH agent with you key to the container use the following

```sh
eval $(ssh-agent -s)
cat ~/.ssh/id_rsa | ssh-add

```


Running in directory where load.yaml is located:

```sh
docker run \
    -v $(pwd):/var/loadtest \
    -v $SSH_AUTH_SOCK:/ssh-agent \
    -e SSH_AUTH_SOCK=/ssh-agent \
    --net host -it \
    rockmagic/yandex-tank-jmeter
```