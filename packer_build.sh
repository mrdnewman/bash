

clear

# --> packer_build.sh
#

_script_name=$(basename $0)
_secret_id="packer"
#_secret_id="boo"
_region="us-east-2"

#set -e

echo -e "\n\n\t\t\t\tRunning \"${_script_name}\" \n\n" && sleep 1

#echo -e "\n==> Validating \"secret-id\".  One moment please  ..."
#aws secretsmanager get-secret-value --secret-id ${_secret_id} > /dev/null 2>&1

#[ $? -ne 0 ] && echo -e "\t==> !!! Secret-id:\"${_secret_id}\" does NOT exist. \
#Exiting !!!\n" && exit 1 || echo -e "\t==> secret-id: Validated -- OK\n"

#echo "==> Fetching Build Secrets. One sec ..."
#export VOMS_BUILD_SEC=$(aws secretsmanager get-secret-value \
#	--secret-id ${_secret_id} --region ${_region} \
#	--output=text | grep ${_secret_id} | sed 's/^.*{//g' | sed 's/}.*$//g')

#echo -e "\t==> Secrets: Retrieved -- OK\n"

echo  -e "\n\n\t\t\t\tSetting Up Default VPC. One Sec ...\n\n" && sleep 1

export _get_VPCid=$(aws ec2 create-default-vpc | grep -i VpcId \
	        | awk -F: '{ print $2 }' | sed 's/\"//g' | sed 's/\,//g')
export _get_IGW=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="${_get_VPCid}" \
	        | grep -i igw | awk -F: '{ print $2 }' | sed 's/\"//g' | sed 's/\,//g' | sed 's/ //g')

echo -e "==> New VPC Created: ${_get_VPCid}"
echo -e "==> Associated Internet Gateway: ${_get_IGW}\n"



export VVOMS_BUILD_SEC=(${VOMS_BUILD_SEC//,/ })

for i in "${VVOMS_BUILD_SEC[@]}"
do

        [[ "${i}" =~ B_RGN ]] && export b_rgn=(${i//?B_RGN?:/}) && b_rgn=(${b_rgn//\"/})

        [[ "${i}" =~ B_VPC ]] && export b_vpc=(${i//?B_VPC?:/}) && b_vpc=(${b_vpc//\"/})

        [[ "${i}" =~ B_SN ]]  && export b_sn=(${i//?B_SN?:/}) && b_sn=(${b_sn//\"/}) 

        [[ "${i}" =~ B_AMI ]] && export b_ami=(${i//?B_AMI?:/}) && b_ami=(${b_ami//\"/}) 

done


echo -e "\n\n\t\t\t\tRunning \"Packer Build\"\n\n\n"


packer build -var "b_ami=${b_ami}" -var "b_rgn=${b_rgn}" \
	-var "b_vpc=${b_vpc}" -color=false ./packer.json 

#packer build -var "b_ami=${b_ami}" -var "b_rgn=${b_rgn}" /
#-var "b_vpc=${b_vpc}" -var "b_sn=${b_sn}" -color=false ./packer.json 




# --> Tear Down VPC

echo -e "\n\n\t\t\t\tBeginning VPC Tear Down. One Sec ...\n\n" && sleep 1
echo -e "==> Deleting all associated subnets"

for i in `aws ec2 describe-subnets --filters Name=vpc-id,Values="${_get_VPCid}" \
	        | grep subnet- | sed -E 's/^.*(subnet-[a-z0-9]+).*$/\1/' | uniq`; do \
		        aws ec2 delete-subnet --subnet-id=$i; done

`aws ec2 describe-subnets --filters Name=vpc-id,Values="${_get_VPCid}" \
	        | grep SubnetId` > /dev/null 2>&1
[[ $? -eq 1 ]] && echo -e "\t==> Subnets deleted - OK\n" || echo -e "\n==> Failed! Manual\
	        removal required!\n"


echo -e "==> Detaching Internet Gateway: ${_get_IGW}"
`aws ec2 detach-internet-gateway --internet-gateway-id="${_get_IGW}" --vpc-id="${_get_VPCid}"`

`aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="${_get_VPCid}"\
	        | grep Attachements` > /dev/null 2>&1
[[ $? -eq 1 ]] && echo -e "\t==> Internet Gateway Detached - OK\n" || echo -e "\t==> Failed! Manual\
	                removal required!"

echo -e "==> Deleting Internet Gateway: ${_get_IGW}"
`aws ec2 delete-internet-gateway --internet-gateway-id "${_get_IGW}"` > /dev/null 2>&1
[[ $? -eq 0 ]] && echo -e "\t==> Internet Gateway Deleted - OK\n" || echo -e "\t==> Nothing to do ...\n"


echo -e "==> Deleting VPC: ${_get_VPCid}"
`aws ec2 delete-vpc --vpc-id "${_get_VPCid}"` > /dev/null 2>&1
[[ $? -ne 0 ]] && echo -e "\t==>Failed! Manual removal required ...\n" \
	        || echo -e "\t==> VPC Deleted - OK\n"

echo  -e "\n\n\t\t\t\tPacker Build Complete ...\n\n"

