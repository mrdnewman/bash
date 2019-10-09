#==============================================================================
#title           :fwdprt-eks_Dash.sh
#description     :This script forwards request from EC2 local port to
#                :kubernetes dashboard port
#
#author          :D. Newman
#date            :7/5/2019
#version         :0.1
#notes           :N/A
#==============================================================================


PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ec2-user/.local/bin:/home/ec2-user/bin
export DISPLAY=:0.0

ps -aux | grep 6443 | grep -v grep
if [ $? -eq 1 ]; then
        nohup kubectl port-forward svc/kubernetes-dashboard \
                -n kube-system 6443:443 >/dev/null 2>&1 &
else
        exit 0
fi
