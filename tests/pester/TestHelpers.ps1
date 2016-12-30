function CleanupTasksAndExecutions {
    $query = "delete from scheduler.task; truncate table scheduler.taskexecution;"
    Invoke-Sqlcmd -ServerInstance . -Database tsqlscheduler -Query $query
}

function GetTaskExecutionCount($identifier = "TestingTask") {
    $query = "select count(*) as ExecutionCount from scheduler.Task as t join scheduler.TaskExecution as te on te.TaskId = t.TaskId where t.Identifier = '$identifier'"
    $result = Invoke-Sqlcmd -ServerInstance . -Database tsqlscheduler -Query $query
    return $result.ExecutionCount
}

function ExecuteTask($identifier = "TestingTask") {
    $query = "exec scheduler.ExecuteTask @identifier = '$identifier';"
    Invoke-Sqlcmd -ServerInstance . -Database tsqlscheduler -Query $query | out-null
}

function InsertTask(
    $identifier = "TestingTask"
    ,$tsqlcommand = "select @@servername"
    ,$startTime = "00:00"
    ,$frequencyType = 1
    ,$frequencyInterval = 0
    ,$notifyOnFailureOperator = "Test Operator"
    ,$availabilityGroup = $null
    ,$isEnabled = $true
) {
    # Deal with nullable parameters
    $agvalue = "null"
    if($availabilitygroup -ne $null) {
        $agvalue = "'$availabilitygroup'"
    }
    
    $query = "insert into scheduler.task (identifier, tsqlcommand, starttime, frequencytype, frequencyinterval, notifyonfailureoperator, IsEnabled, AvailabilityGroup) values ('$identifier', '$tsqlcommand', '$startTime', $frequencyType, $frequencyInterval, '$notifyOnFailureOperator', '$isEnabled', $agvalue);"
    Invoke-Sqlcmd -ServerInstance . -Database tsqlscheduler -Query $query
}