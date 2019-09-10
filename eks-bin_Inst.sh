#!/usr/bin/env bash

#==============================================================================
#title           :eks-bin_Inst.sh
#description     :This script will install EKS binaries.
#author          :D. Newman
#date            :9/8/2019
#version         :0.1
#notes           :Install EKS binaries enabling one to build out clusters
#==============================================================================


clear
echo -e "\n\n\t\t\t\tStarting EKS & Kube Binaries Installation...\n\n"

valFun () {

   echo -e "\n <> Retrieving $i binary ... \n"

   if [[ -f /tmp/"${i}" ]]; then
         echo -e "    -- Retrieved successfully ..."
   else
         echo -e "    -- Failure to retrieve binary ..."
         echo -e "       -- Exiting w/ error !!!\n"
         exit 1
   fi

   sudo mv /tmp/"${i}" /usr/local/bin/

   if [[ -f /usr/local/bin/"${i}" ]]; then
        echo -e "    -- Stored successfully in /usr/local/bin...\n"
   else
        echo -e "    -- Failure to store binary  ... "
        echo -e "       -- Exiting w/ error !!!\n"
        exit 1
   fi

   # Make binaries executable
   chmod +x /usr/local/bin/"${i}"

 }
 
 for i in eksctl kubectl aws-iam-authenticator
 do
   case $i in
        eksctl)

          curl --silent --location \
          "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" \
          | tar xz -C /tmp

          valFun
          ;;

        kubectl)

          wget --quiet -P /tmp \
          https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

          valFun
          ;;
        aws*)

          wget --quiet -P /tmp https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator

          valFun
          ;;
   esac

done



echo -e "\n\n\t\t\t\tEKS & Kube Binaries Installation Complete ...\n\n"

 
 
 
