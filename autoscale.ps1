# CONFIG
$THRESHOLD_UP = 80
$THRESHOLD_DOWN = 20
$CHECK_INTERVAL = 30
$CHECKS_BEFORE_ACTION = 3
$LAB_PATH = "C:\Users\rabbitSix\Desktop\ansible-multiserver-lab"
$high_count = 0
$low_count = 0
$web03_running = $false

function Get-CPUUsage {
    param($ip)
    $result = ssh -i ".vagrant\machines\control\vmware_desktop\private_key" -o StrictHostKeyChecking=no vagrant@192.168.200.10 "ansible $ip -m shell -a 'cat /proc/loadavg' 2>/dev/null | grep -oP '^\d+\.\d+'"
    if ($result -match "(\d+\.\d+)") {
        return [math]::Round([float]$Matches[1] * 100, 1)
    }
    return 0
}

function Update-LB {
    param($action)
    if ($action -eq "add") {
        $servers = "server 192.168.200.12; server 192.168.200.13; server 192.168.200.15;"
    } else {
        $servers = "server 192.168.200.12; server 192.168.200.13;"
    }
    ssh -i ".vagrant\machines\control\vmware_desktop\private_key" -o StrictHostKeyChecking=no vagrant@192.168.200.10 "ansible loadbalancer -m shell -a 'sudo tee /etc/nginx/sites-available/loadbalancer.conf <<EOF
upstream webservers { $servers }
server { listen 80; location / { proxy_pass http://webservers; } }
EOF
sudo systemctl restart nginx' --become"
}

function Scale-Up {
    Write-Host "[$(Get-Date)] SCALE UP - lancement web03"
    Set-Location $LAB_PATH
    vagrant up web03
    Start-Sleep -Seconds 60
ssh -i ".vagrant\machines\control\vmware_desktop\private_key" -o StrictHostKeyChecking=no vagrant@192.168.200.10 "ssh-keyscan 192.168.200.15 >> ~/.ssh/known_hosts && ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no vagrant@192.168.200.15"
ssh -i ".vagrant\machines\control\vmware_desktop\private_key" -o StrictHostKeyChecking=no vagrant@192.168.200.10 "cd ~ && ansible-playbook ansible/playbooks/nginx.yml --limit web03"
ssh -i ".vagrant\machines\control\vmware_desktop\private_key" -o StrictHostKeyChecking=no vagrant@192.168.200.10 "cd ~ && ansible-playbook ansible/playbooks/security.yml --limit web03"
    Update-LB "add"
    $script:web03_running = $true
    Write-Host "[$(Get-Date)] web03 ajoute au pool"
}

function Scale-Down {
    Write-Host "[$(Get-Date)] SCALE DOWN - arret web03"
    Update-LB "remove"
    Set-Location $LAB_PATH
    vagrant halt web03
    $script:web03_running = $false
    Write-Host "[$(Get-Date)] web03 retire du pool"
}

Write-Host "[$(Get-Date)] Autoscaler demarre"
while ($true) {
    $CPU1 = Get-CPUUsage "web01"
    $CPU2 = Get-CPUUsage "web02"
    $AVG = [math]::Round(($CPU1 + $CPU2) / 2, 1)
    Write-Host "[$(Get-Date)] CPU web01=$CPU1% web02=$CPU2% avg=$AVG%"
    if ($AVG -gt $THRESHOLD_UP) {
        $high_count++
        $low_count = 0
        Write-Host "[$(Get-Date)] CPU eleve check $high_count/$CHECKS_BEFORE_ACTION"
        if ($high_count -ge $CHECKS_BEFORE_ACTION -and -not $web03_running) {
            Scale-Up
            $high_count = 0
        }
    } elseif ($AVG -lt $THRESHOLD_DOWN) {
        $low_count++
        $high_count = 0
        Write-Host "[$(Get-Date)] CPU bas check $low_count/$CHECKS_BEFORE_ACTION"
        if ($low_count -ge $CHECKS_BEFORE_ACTION -and $web03_running) {
            Scale-Down
            $low_count = 0
        }
    } else {
        $high_count = 0
        $low_count = 0
    }
    Start-Sleep -Seconds $CHECK_INTERVAL
}
