# FROM ubuntu:22.04

FROM --platform=linux/amd64 ghcr.io/foundry-rs/foundry:latest

# install bash
RUN apk update && apk upgrade && apk add bash

# clone points point-guard repo
RUN git clone https://github.com/yieldnest/point-guard.git

WORKDIR /point-guard/contracts

# ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.foundry/bin

# RUN apt-get update \
#  && apt-get install curl git build-essential sudo software-properties-common python3 python3-pip -y

#  && sudo add-apt-repository ppa:ethereum/ethereum -y \
#  && sudo apt-get update \
#  && sudo apt-get install solc -y \
#  && pip3 install slither-analyzer solc-select \
#  && solc-select install 0.8.24 \
#  && solc-select use 0.8.24 \
#  # install foundry
#  && curl -L https://foundry.paradigm.xyz | bash \
#  && foundryup \
#  && forge update lib/forge-std \
#  # https://github.com/paritytech/substrate/issues/1070
#  && curl https://sh.rustup.rs -sSf | sh -s -- -y

# # Clone the GitHub repository
# RUN git clone https://github.com/yieldnest/point-guard.git /root/point-guard

# # Set the working directory
# WORKDIR /root/point-guard

# # Run forge build command in the context of the cloned repository
# RUN forge build

# docker build -t sol-dev .
# docker run -it --rm -v "/${PWD}:/amplify-contracts" sol-dev bash