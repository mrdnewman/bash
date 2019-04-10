#!/bin/bash



# --> vomsBuild.sh
#

#set -e

usage="USAGE: ./vomsBuild.sh <secret_id> <region>"
[[ -z "$1" ]] && echo "secret_id. ${usage}" && exit 1
[[ -z "$2" ]] && echo "region. ${usage}" && exit 1

export _secret_id=$1
export _region=$2
_script_name=$(basename $0)


echo -e "\n\n\t\t\t\tRunning \"${_script_name}\" \n\n" && sleep 1
echo -e "\n==> Validating Secret-ID.  One moment please  ..."

aws secretsmanager get-secret-value --secret-id ${_secret_id} > /dev/null 2>&1
[[ $? -ne 0 ]] && echo -e "\t==> Failed! Secret-ID: \"${_secret_id}\" does NOT exist ...\n" \
	&& exit 1 || echo -e "\t==> Secret-ID: Validated -- OK\n"

echo "==> Fetching Build Secrets. One sec ..."

aws secretsmanager get-secret-value --secret-id ${_secret_id} --region ${_region} > /dev/null 2>&1
[[ $? -ne 0 ]] && echo -e "\t==> Failed. Your REGION may be incorrect ...\n"\
&& exit 1 || echo && export VOMS_BUILD_SEC="$(aws secretsmanager get-secret-value --secret-id\
	${_secret_id} --region ${_region} --output=text | grep ${_secret_id}\
	| sed 's/^.*{//g' | sed 's/}.*$//g')" && echo -e "\t==> Secrets: Retrieved -- OK\n"


export VVOMS_BUILD_SEC=(${VOMS_BUILD_SEC//,/ })
for i in "${VVOMS_BUILD_SEC[@]}"
do

        [[ "${i}" =~ B_AMI ]] && export b_ami=(${i//?B_AMI?:/}) && b_ami=(${b_ami//\"/})

        [[ "${i}" =~ B_RGN ]] && export b_rgn=(${i//?B_RGN?:/}) && b_rgn=(${b_rgn//\"/})

        [[ "${i}" =~ B_AMI ]] && export b_ami=(${i//?B_AMI?:/}) && b_ami=(${b_ami//\"/}) 

        [[ "${i}" =~ REDIS_URL ]] && export redis_url=(${i//?REDIS_URL?:/}) && redis_url=(${redis_url//\"/}) 

        [[ "${i}" =~ S3_URL ]] && export s3_url=(${i//?S3_URL?:/}) && s3_url=(${s3_url//\"/}) 

        [[ "${i}" =~ ARTI_URL ]] && export arti_url=(${i//?ARTI_URL?:/}) && arti_url=(${arti_url//\"/}) 

        [[ "${i}" =~ ARTIFACT ]] && export artifact=(${i//?ARTIFACT?:/}) && artifact=(${artifact//\"/}) 

done


echo  -e "\n\n\t\t\t\tSetting Up Default VPC. One Sec ...\n\n" && sleep 1

b_vpc=$(aws ec2 create-default-vpc | grep -i VpcId \
	        | awk -F: '{ print $2 }' | sed 's/\"//g' | sed 's/\,//g')


export b_vpc=(${b_vpc//\'/})
export _get_IGW=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="${b_vpc}" \
	        | grep -i igw | awk -F: '{ print $2 }' | sed 's/\"//g' | sed 's/\,//g' | sed 's/ //g')


echo -e "==> New VPC Created: ${b_vpc}"
echo -e "==> Associated Internet Gateway: ${_get_IGW}\n"


echo -e "\n\n\t\t\t\tRunning \"Packer Build\"\n\n"


packer build -var "b_ami=${b_ami}" -var "b_rgn=${b_rgn}" \
	-var "redis_url=${redis_url}" -var "s3_url=${s3_url}"\
	-var "arti_url=${arti_url}" -var "artifact=${artifact}"\
       	-var "b_vpc=${b_vpc}" -color=false ./packer.json 

[[ $? -eq 1 ]] && _outcome="Packer Build: Failed ..."\
	|| _outcome="Packer Build: Complete ..." 


# --> Clean Up VPC Environment ...
echo -e "\n\n\t\t\t\tBeginning VPC Clean Up. One Sec ...\n\n" && sleep 1
echo -e "==> Deleting all associated subnets"

for i in `aws ec2 describe-subnets --filters Name=vpc-id,Values="${b_vpc}" \
	        | grep subnet- | sed -E 's/^.*(subnet-[a-z0-9]+).*$/\1/' | uniq`; do \
		        aws ec2 delete-subnet --subnet-id=$i; done

aws ec2 describe-subnets --filters Name=vpc-id,Values="${b_vpc}" \
	        | grep SubnetId > /dev/null 2>&1

[[ $? -eq 1 ]] && echo -e "\t==> Subnets deleted - OK\n" || echo -e "\n==> Failed! Manual\
	        removal required!\n"


echo -e "==> Detaching Internet Gateway: ${_get_IGW}"
aws ec2 detach-internet-gateway --internet-gateway-id="${_get_IGW}"\
       	--vpc-id="${b_vpc}"

aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="${b_vpc}"\
	        | grep Attachements > /dev/null 2>&1

[[ $? -eq 1 ]] && echo -e "\t==> Internet Gateway Detached - OK\n" || \
	echo -e "\t==> Failed! Manual removal required!"

echo -e "==> Deleting Internet Gateway: ${_get_IGW}"
aws ec2 delete-internet-gateway --internet-gateway-id "${_get_IGW}" > /dev/null 2>&1

[[ $? -eq 0 ]] && echo -e "\t==> Internet Gateway Deleted - OK\n" || \
	echo -e "\t==> Nothing to do ...\n"


echo -e "==> Deleting VPC: ${b_vpc}"
aws ec2 delete-vpc --vpc-id "${b_vpc}" > /dev/null 2>&1

[[ $? -ne 0 ]] && echo -e "\t==>Failed! Manual removal required ...\n" \
	        || echo -e "\t==> VPC Clean Up Complete - OK\n"


echo  -e "\n\n\t\t\t\t${_outcome}\n\n"
