# create group, sql server
az>> group create -g jung-projects-serverless -l japaneast
az>> sql server create -g jung-projects-serverless -n jungprojectsserverless -l japaneast -u labs -p Strong-password0
az>> sql db create -g jung-projects-serverless -n db -s jungprojectsserverless
az>> sql db show-connection-string -c ado.net --server jungprojectsserverless
"Server=tcp:jungprojectsserverless.database.windows.net,1433;Initial Catalog=db;Persist Security Info=False;User ID=labs;Password=Strong-password0;MultipleActiveResultSets=False;Encrypt=true;TrustServerCertificate=False;Connection Timeout=30;"

# create servicebus
az>> servicebus namespace create -g jung-projects-serverless --sku Premium -n jungprojectsserverless -l japaneast --public-network-access Disabled
az>> servicebus queue create -g jung-projects-serverless --namespace-name jungprojectsserverless -n events.todo.newitem
az>> servicebus queue create -g jung-projects-serverless --namespace-name jungprojectsserverless -n events.todo.itemsaved
az>> servicebus namespace authorization-rule keys list -n RootManageSharedAccessKey -g jung-projects-serverless --query primaryConnectionString -o tsv --namespace-name jungprojectsserverless
# servicebus endpoint
"Endpoint=sb://jungprojectsserverless.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=thtKBZBMEGR7VksoDStnbGC6uieBxpd1Y+ASbHT5rtA="

# create signalr
az>> signalr create -g jung-projects-serverless --service-mode Serverless --sku Standard_S1 -n jungprojectsserverless
az>> signalr key list -g jung-projects-serverless -n jungprojectsserverless -o tsv --query 'primaryConnectionString'
"Endpoint=https://jungprojectsserverless.service.signalr.net;AccessKey=0OJh6TtrLiCisQ5IQ0oABA6EStPxQcuKKt5JHm9NdHY=;Version=1.0;"

# define variable
sqlcs='Server=tcp:jungprojectsserverless.database.windows.net,1433;Initial Catalog=db;Persist Security Info=False;User ID=labs;Password=Strong-password0;MultipleActiveResultSets=False;Encrypt=true;TrustServerCertificate=False;Connection Timeout=30;'
servicebuscs='Endpoint=sb://jungprojectsserverless.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=eOGOoi6D4H7paK3QiDzyLdH/EZHx9X7Tk+ASbE2OOCk='
signalrcs='Endpoint=https://jungprojectsserverless.service.signalr.net;AccessKey=0OJh6TtrLiCisQ5IQ0oABA6EStPxQcuKKt5JHm9NdHY=;Version=1.0;'

$sqlcs
$servicebuscs
$signalrcs

# create webapp
az webapp up -g jung-projects-serverless --plan serverless-01 --sku B1 --os-type Linux --runtime dotnetcore:6.0 -l japaneast -n jungserverlessweb

# setup vnet
az>> network vnet create -g jung-projects-serverless -n vnet -l japaneast --address-prefixes 10.20.0.0/16
# db subnet
az>> network vnet subnet create -g jung-projects-serverless --vnet-name vnet -n db --address-prefixes 10.20.1.0/24
# queue subnet
az>> network vnet subnet create -g jung-projects-serverless --vnet-name vnet -n queue --address-prefixes 10.20.2.0/24
# webapp subnet
network vnet subnet create -g jung-projects-serverless --vnet-name vnet -n webapp --address-prefixes 10.20.3.0/24
# todolist subnet
network vnet subnet create -g jung-projects-serverless --vnet-name vnet -n todolist --address-prefixes 10.20.4.0/24

# network setup
create subnet for db
create private endpoint in sql server
add private endpoint in webapp

# create appservice plan for functionapp
az>> appservice plan create -g jung-projects-serverless -n vnetplan -l japaneast --sku P1V2
# create functionapp
az>> storage account create -g jung-projects-serverless --sku Standard_LRS -l japaneast -n jungprojectsserverless 
az>> functionapp create -g jung-projects-serverless --runtime dotnet --functions-version 4 -n jungserverlesstodolist --storage-account jungprojectsserverless --vnet vnet --subnet todolist --plan vnetplan
# create functionapp settings
az functionapp config appsettings set -g jung-projects-serverless -n jungserverlesstodolist --settings ServiceBusConnectionString=$servicebuscs SqlServerConnectionString="$sqlcs" SignalRConnectionString=$signalrcs