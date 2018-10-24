#!/bin/bash

func () {
  printf "I received $1"
  
}

vpcid=JOHNSVPC
subnetid=JOHNSSUB

para="ParameterKey=VpcId,ParameterValue=$vpcid ParameterKey=KeyName,ParameterValue=Sensor ParameterKey=SubnetId,ParameterValue=$subnetid ParameterKey=NodeName,ParameterValue=Sensor"
func "$para"
