#!/bin/bash
PS3='
Choose what to do: '
choices=("Start the project" "Destroy intances" "Launch Ansible config")
select choice in "${choices[@]}"; do
  case $choice in
    "Start the project")
      cd terraform
      terraform init
      terraform apply -auto-approve
      cd ../ansible
      i=1
      sp="/-\|"
      counter=0
      printf "Waiting for AWS instances to be available ...  "
      until [ $counter -gt 3000000 ]
      do
        printf "\b${sp:i++%${#sp}:1}"
        ((counter++))
      done
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible_hosts ansible_playbook_config.yml
      exit
      ;;
    "Destroy intances")
      rm -rf client.ovpn
      cd terraform
      terraform apply -destroy
      exit
      ;;
    "Launch Ansible config")
      cd ansible
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible_hosts ansible_playbook_config.yml
      exit
      ;;
    *) echo "Invalid option please select between 1 and 2";;
  esac
done
