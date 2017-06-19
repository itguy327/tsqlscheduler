# tsqlScheduler

Create agent jobs from definitions stored in SQL tables.  Currently supports the following features:

- Schedule tasks to run on a schedule every day, or every N hours/minutes/seconds
- Automatically create a SQL Agent job from each task
- Provide logging of task execution history (runtime, success/failure, error messages)
- Conditional execution of tasks based on replica status - if an availability group is linked to a task that task will only run when that node is the primary replica

This is intended as an administrative tool and as such requires and will schedule jobs to run with sysadmin (sa) privileges.

## Installation

Clone the repository and . source the DeployAllObjects.ps1 script file.  After that execute the Deploy-SchedulerSolution.  It assumes integrated security - if you need a username and password you need to edit the deployment powershell, or execute the scripts manually.  The solution will be deployed into the scheduler schema.

```
. ./src/DeployAllObjects.ps1
Deploy-SchedulerSolution -Server localhost -Database tsqlscheduler -agMode $false
```

If you're deploying to an AG database specify agMode as true.   If you're deploying scheduler for the whole instance use standalone mode (agMode false).

The script requires SQL 2016 SP1.

The objects can be removed with the RemoveAllObjects SQL script.

## Usage

Add tasks to the scheduler.Task table, and then run the procedure scheduler.CreateJobFromTask passing either the task Id or Identifier to create a SQL Agent job which will execute your task.  If you make updates to the task definition which change the schedule you should specify @overwriteExisting = 1 to recreate the schedule.

You can monitor executions via the scheduler.TaskExecution table.  Task configuration history is available in the scheduler.TaskHistory table, or by querying the scheduler.Task table with a temporal query.

To create a job which will periodically loop through your task table and upsert jobs as required run the following script.  You should run this script from the database that contains your task table.  The job will be named DATABASENAME-UpsertJobsForAllTasks, will run once every 10 minutes and will not generate errors by default.  You will need to modify the operator name to match an operator on your system.

```
declare @command nvarchar(max) = N'exec ' + db_name() + N'.scheduler.UpsertJobsForAllTasks';
declare @identifier nvarchar(128) = db_name() + N'-UpsertJobsForAllTasks';

insert into scheduler.Task
( Identifier, TSQLCommand, StartTime, FrequencyType, FrequencyInterval, NotifyOnFailureOperator, IsNotifyOnFailure )
values
( @identifier, @command, '00:00', 3, 10, 'Test Operator', 0 );

exec scheduler.CreateJobFromTask @identifier = @identifier, @overwriteExisting = 1;
```

The script uses the temporal table field on the Task table and the jobs last modified date to determine which jobs require modification.

If you set a task to deleted (IsDelete = 1) the process will also remove the agent job associated with that task.

## How it works

The Task table holds one row for each task that should be executed in the context of that database.  When an agent job is created from this task a job is created as a wrapper around the schedule.ExecuteTask stored procedure.  This procedure uses the metadata from the Task table to ultimately execute the TSQLCommand with sp_executesql.

## Tests
 
The tests are currently hardcoded to point at a database called tsqlscheduler on a local instance.  A successful run looks something like this:

![Pester Tests](/PesterTests.png?raw=true "Pester Test Results")

## Code Style

- Keywords should be in lowercase
- Identifiers should not be escaped with brackets unless required (better to avoid using a reserved keyword)
- Use <> rather than !=
- Variables use lowerCamelCase
- Constants in ALL_CAPS
- Terminate statements with a semicolon