# mydns
> my local dns manager

## Quick reference
- maintained by [simanchou(周星星)](https://github.com/simanchou/mydns-frontend)
- dns service power by [coredns](https://github.com/coredns/coredns)
- frontend power by [vue-admin-template](http://panjiachen.github.io/vue-admin-template)


# How to use this image
| Role | Hostname | IP | 
| --------- | --------- | --------- |
| Master | master | 192.168.8.100 |
| Slave | slave | 192.168.8.200 | 
|  |  |  |

```bash

# Master
$ docker run -d --name mydns -p8000:80 -p53:53/udp -e SLAVE=192.168.8.200 -e DEBUG_ON=true simanchou/mydns:0.1

# Slave
$ docker run -d --name mydns -p8000:80 -p53:53/udp -e MASTER=192.168.8.100:8000 -e DEBUG_ON=true simanchou/mydns:0.1

```
The following environment variables are also honored for configuring your mydns instance:
- -e MASTER=... (told Slave the addr of Master,to get sync)
- -e SLAVE=... (told Master the addr of Slave which are allow to get sync)
- -e DEBUG_ON=... (turn on debug when you set true)

# ... via docker stack deploy or docker-compose
Example stack.yml for Master:
```
version: '3.1'

services:
  mydns:
    image: simanchou/mydns
    restart: always
    ports:
      - 8000:80
      - 53:53/udp
    environment:
      SLAVE: "192.168.8.200"
      DEBUG_ON: true
    volumes:
      - mydns:/mydns

volumes:
  mydns:

```
Run docker stack deploy -c stack.yml mydns (or docker-compose -f stack.yml up), wait for it to initialize completely, and visit http://swarm-ip:8000, http://localhost:8000, or http://host-ip:8000 (as appropriate).
login by default username admin:
- username:admin
- password:123456

