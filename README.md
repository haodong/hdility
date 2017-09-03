# HDility

Nothing special.

I usually wrote scripts to fasten my geek life.

Now I'm putting them here one by one to share.

## installMOTD
- A script to install MOTD on Debian.
- Preview:

    ![](https://haodong.me/images/contents/2017-01-21-debian-motd.png)

- Usage: `wget https://raw.githubusercontent.com/haodong/hdility/master/installMOTD.sh - | sh`
- [Readmore](https://haodong.me/post/2017-01-21-debian-motd.html)

## NATctl
- A controller to add/list/reset Traffic Transfer through iptables.
- Installation: `wget https://raw.githubusercontent.com/haodong/hdility/master/NATctl -O /usr/local/bin/NATctl && sudo chmod +x /usr/local/bin/NATctl`
- Usage:
```
> NATctl -h
This controller can help you handle Traffic Transfer through iptables.
Usage: iptNAT [-c $cmd] [-i #ID] [-f @IP] [-p #Port] [-t @IP] [-b #Port] [-u]
    -c: Give a command to implement. Available commands are:
        add: Add new rules.
        del: Delete existing rules.
            -i: The #th line of PREROUTING chain for inserting (add mode) and for removing (delete mode).
            -d: The #th line of POSTROUTING chain for inserting (add mode) and for removing (delete mode).
            -f: From the IP. By default use 'dig' function to detect its public IP. Must be specified if the host has multiple public IPs.
            -t: To the IP, namely the target IP address.
            -p: From the Port.
            -b: To the Port, namely the target port.
            -o: Specify Protocal.
        list: List your NAT iptables (exclude MASQUERADE and show PREROUTING & POSTROUTING only).
        reset: Reset the two chains, cleaning all added Traffic Transfer rules.

The code was written by Hao Dong under GPL-3.0 License.
```
- Example:
    1. If a user from host A want to access host C (1.1.1.1), but the traffic between A and C is two slow to work.
    2. Fortunately there is another host B (0.0.0.0), whose traffic torward host C is faster than A.
    3. Also the route between A and B is very good.
    4. Then the user should use the following code at host B.
```
> NATctl -c add -f 0.0.0.0 -p 60001 -t 1.1.1.1 -b 22
Adding TCP rules ...
Done.

## To delete
> NATctl -c del -f 0.0.0.0 -p 60001 -t 1.1.1.1 -b 22

## To revert all
> NATctl -c reset
This will clean up all rules on chains of PREROUTING and POSTROUTING.
Are you sure?(y/n)? y
Cleaning ...
Done.
```
- [Readmore](https://haodong.me/post/2017-01-22-nat-controller.html)

## Buy me a cup of milk.
Milk is good in which it can refresh my spirit and bring more energy to me for developing.

![](images/alipay.png)          ![](images/wechat.png)

**Thank you!**

