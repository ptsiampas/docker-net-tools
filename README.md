# Net Tools for diagnosing networking problems

I use this image to test and diagnose various networking problems with my swarm or local docker, it can be run as a service, and background or foreground.

Following tools have been installed:

* [mtr](https://www.linode.com/docs/networking/diagnostics/diagnosing-network-issues-with-mtr/) Matt's traceroute (MTR)
* [wget](https://www.webhostface.com/kb/knowledgebase/examples-using-wget/) http requests
* [curl](https://curl.haxx.se/docs/manpage.html) http requests
* bash - because I perferer it
* [htop](https://hisham.hm/htop/) nice version of top
* [tcpdump](https://hackertarget.com/tcpdump-examples/) - dump traffic on a network
* [nmap](https://hackertarget.com/nmap-cheatsheet-a-quick-reference-guide/) network mapper
* [iperf0](https://iperf.fr/) Bandwidth Measurement Tool
* openssh-client - well ssh just in case
* [jq](https://stedolan.github.io/jq/tutorial/) dumps JSON data from an API very handy
* [nmap-ncat](https://nmap.org/ncat/guide/ncat-tricks.html) great for direct port access
* [bind-tools](https://pkgs.alpinelinux.org/contents?branch=edge&name=bind-tools&arch=x86&repo=main) this is how you get dig, host, nslookup etc.

## Usage

### docker

Quick Run just to test stuff.

```bash
$ docker run --rm -it --entrypoint=bash --network bridge  ptsiampas/docker-net-tools
bash-4.3# 
```

Run in the background

```bash
$ docker run -d --network bridge  ptsiampas/docker-net-tools
b30f9a0a6e7f2e59c77cdc14b7316b63e83d093378e6fac93372277fa995f578
$ docker ps
CONTAINER ID        IMAGE                        COMMAND
b30f9a0a6e7f        ptsiampas/docker-net-tools   "/start.sh"
$ docker exec -it b30f9a0a6e7f bash
bash-4.3# 
$ docker container stop b30f9a0a6e7f
b30f9a0a6e7f
$ docker container rm b30f9a0a6e7f
b30f9a0a6e7f
```

### service

This is a little more involved, but the main thing to focus on is, what network you want to attach too (the network must be attachable) and that you constrain the service to the node your actually on. (yes my dev swarm box is named [dogmeat](https://fallout.fandom.com/wiki/Dogmeat_(Fallout_4))[^1] - Fallout4!)

```bash
$ docker service create \
--name net-tools --network public \
--constraint "node.hostname == dogmeat" \
ptsiampas/docker-net-tools

9ok1j0uptpnjskue9lcu1holi
overall progress: 1 out of 1 tasks 
1/1: running   [==================================================>] 
verify: Service converged 
$ docker service ps net-tools
ID                  NAME                IMAGE
ydevpuazx3dt        net-tools.1         ptsiampas/docker-net-tools:latest

$ docker ps --format "table {{.Image}}\t{{.Names}}"
IMAGE                               NAMES
ptsiampas/docker-net-tools:latest   net-tools.1.ydevpuazx3dt5jpj92k0pfka8

$ docker exec -it net-tools.1.ydevpuazx3dt5jpj92k0pfka8 bash
bash-4.3# 

$ docker service rm net-tools
net-tools
```

### stack

You have two options when running it in a stack:

1. if you just want to test a network and have the tool available, you simply create a stack file and run it.
2. if you are trying to diagnose a full stack you can include the service information inside that stack file.

Running it on it's own.

```yml
version: '3.3'
networks:
  traefik-public:
    external: true
services:
  nettools:
    image: ptsiampas/docker-net-tools
    networks:
      traefik-public: null
    deploy:
      placement:
        constraints:
         - node.hostname == dogmeat
```

Launch it and then you can connect to it the same way you would if you launched it as a service.

```bash
$ docker stack deploy --with-registry-auth -c net_tools.yml net-tools
```



servRunning it within a stack, add lines from 6-14 to your stack.

```yaml
version: '3.3'
networks:
  traefik-public:
    external: true
services:
  nettools:
    image: ptsiampas/docker-net-tools
    networks:
      default: null
      traefik-public: null
    deploy:
      placement:
        constraints:
         - node.hostname == dogmeat
  backend:
    deploy:
      labels:
        traefik.enable: "true"
        traefik.frontend.rule: PathPrefix:/api
        traefik.port: '80'
    image: backend:latest
  frontend:
    deploy:
      labels:
        traefik.enable: "true"
        traefik.frontend.rule: PathPrefix:/
        traefik.port: '80'
    image: frontend:latest
  proxy:
    command: 
      - "--docker"
      - "--docker.swarmmode"
      - "--docker.watch" 
      - "--docker.exposedbydefault=false"
      - "--logLevel=INFO" 
      - "--accessLog" 
      - "--web"
    deploy:
      labels:
        traefik.docker.network: traefik-public
        traefik.enable: "true"
        traefik.frontend.rule: Host:blog.wiredelf.dev
        traefik.port: '80'
        traefik.servicehttp.frontend.entryPoints: http
        traefik.servicehttp.frontend.redirect.entryPoint: https
        traefik.servicehttps.frontend.entryPoints: https
        traefik.tags: traefik-public
      placement:
        constraints:
        - node.role == manager
    image: traefik:v1.6
    networks:
      default: null
      traefik-public: null
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock:rw

```



Launch it and then you can connect to it the same way you would if you launched it as a service.

```bash
$ docker stack deploy --with-registry-auth -c "app.yml" "random-app"
```



[^1]: Dogmeat is modelled after River, a female German Shepherd, owned by Michelle Burgess who is the wife of [Joel Burgess](https://fallout.fandom.com/wiki/Joel_Burgess), Senior Designer at Bethesda Softworks