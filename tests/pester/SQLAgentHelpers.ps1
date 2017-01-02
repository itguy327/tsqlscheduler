function CleanupExistingAgentJob {
	$query = "exec sp_delete_job @job_name = 'CreateAgentJobTestJob';"
    # Ignore any errors if the job doesn't already exist
    Invoke-Sqlcmd -ServerInstance . -Database msdb -Query $query -ErrorAction SilentlyContinue
}

function CreateAgentJob(
    $overwriteExisting = 0
    ,$command = "select @@servername"
) {
    $query = "exec scheduler.CreateAgentJob @jobname = 'CreateAgentJobTestJob', @command = N'$command', @frequencyType = 'hour', @frequencyInterval = 1, @startTime = '00:00', @notifyOperator = 'Test Operator', @overwriteExisting = $overwriteExisting";
    Invoke-Sqlcmd -ServerInstance . -Database tsqlscheduler -Query $query -ErrorAction Stop

}

function CheckIfAgentJobExists {
    $query = "select count(*) as JobCount from msdb.dbo.sysjobs as j where j.name = 'CreateAgentJobTestJob';"
    $result = Invoke-Sqlcmd -ServerInstance . -Database msdb -Query $query 
    $count = $result.JobCount
    return ($result.JobCount -eq 1)
}

function GetAgentJobCommand {
    $query = "select js.command as Command from sysjobs as j join sysjobsteps as js on js.job_id = j.job_id where j.name = N'CreateAgentJobTestJob';"
    $result = Invoke-Sqlcmd -ServerInstance . -Database msdb -Query $query 
    return $result.Command
}