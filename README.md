# Building ModSecurity WAF on Kong API Gateway

![N|Solid](https://konghq.com/wp-content/uploads/2017/09/kong-logo.png) ![N|Solid](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRftH-Nof5iVPEDTeul5tZLUWBo5ALCkx3Fbe1kUjc-rJtSMtRk&s)

Kong is one of the most popular open source Microservice API Gateway which manages the communication between clients and microservices via API. It’s a Lua application running in Nginx and made possible by the lua-nginx-module.

A great tool for securing Nginx-based applications is ModSecurity, used by over a million sites around the world. It protects against a broad range of Layer 7 attacks, such as SQL injection (SQLi), local file inclusion (LFI), and cross‑site scripting (XSS), which together accounted for 95% of known Layer 7 attacks in Q1 2017, according to Akamai. Best of all, ModSecurity is open source.

This repo build and run a Docker container of ModSecurity WAF system on Kong API Gateway server which runs on the top of Nginx server, so the installation is done basically on Nginx itself with some modifications on the Kong-Nginx configuration files. 


# Docker Image Implementation steps:
 - Install Kong version 0.14.1 on Ubuntu 18.04
 - Install all required perequisite pckages for ModSecurity
 - Download the NGINX Connector for ModSecurity and Compile it as a Dynamic Module
 - Configure ModSecurity
 - Delete all temp and unnecessary files
 - Configure and Enable ModSecurity on OpenResty-Nginx
 - Configure and Enable ModSecurity on Kong-Nginx

# The below versions will be used in the implementation
 - Ubuntu Bionic 18.04
 - Kong 1.3.0
 - OpenResty (Nginx + LuaJIT) 1.15.8.1
 - ModSecurity 3.0

## Note:
The rules can be added and controlled from the main.conf file that is in the root of the repo. It's currently consists of a test rule to block a request when hitting: "curl localhost?testparam=test", for more rules configuration, please check the below link:
https://www.modsecurity.org/CRS/Documentation/