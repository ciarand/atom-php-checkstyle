{exec} = require 'child_process'

# Wrapper class for all shell commands
# Provides shelling out commands so it is performed in one place
class Shell

    # Constructor
    # @param @command The shell command we will execute
    constructor: (@commands) ->

    # Executor
    # Execute the shell command
    # @param callback The callback once the shell command is complete
    execute: (callback) ->
        overall = ''
        for command in @commands
            overall += command.getCommand() + '; '

        console.log "[php-checkstyle]" + overall
        exec overall, callback

#
# Base command class for others to extend
#
class BaseCommand
  # Constructor
  # @param @path   The path to the file we want to run the command on
  # @param @config The configuration for the command
  constructor:(@path, @config) ->


# Phpcs command to represent phpcs
class PhpcsCommand extends BaseCommand

    # Getter for the command to execute
    getCommand: ->
        command = ''
        command += @config.executablePath + " --standard=" + @config.standard
        command += " -n"  if @config.warnings is false
        command += ' --report=checkstyle '
        command += @path

    # Given the report, now process into workable data
    # @param err    Any errors occured via exec
    # @param stdout Overall standard output
    # @param stderr Overall standard errors
    process: (error, stdout, stderr) ->
        pattern = /.*line="(.+?)" column="(.+?)" severity="(.+?)" message="(.*)" source.*/g
        errorList = []
        while (line = pattern.exec(stdout)) isnt null
            item = [line[1], line[4]]
            errorList.push item
        return errorList


# Linter command
class LinterCommand extends BaseCommand

    # Getter for the command to execute
    getCommand: ->
        command = @config.executablePath + " -l -d display_errors=On " + @path

    # Given the report, now process into workable data
    # @param err    Any errors occured via exec
    # @param stdout Overall standard output
    # @param stderr Overall standard errors
    process: (error, stdout, stderr) ->
        pattern = /(.*) on line (.*)/g
        errorList = []
        while (line = pattern.exec(stdout)) isnt null
            item = [line[2], line[1]]
            errorList.push item
        return errorList


# Mess Detection command (utilising phpmd)
class MessDetectorCommand extends BaseCommand

    # Getter for the command to execute
    getCommand: ->
        command = @config.executablePath + ' ' + @path + ' text ' + @config.ruleSets

    # Given the report, now process into workable data
    # @param err    Any errors occured via exec
    # @param stdout Overall standard output
    # @param stderr Overall standard errors
    process: (error, stdout, stderr) ->
        pattern = /.*:(\d+)[ \t]+(.*)/g
        errorList = []
        while (line = pattern.exec(stdout)) isnt null
            item = [line[1], line[2]]
            errorList.push item
        return errorList


# PHP CS Fixer command
class PhpcsFixerCommand extends BaseCommand

    # Formulate the php-cs-fixer command
    getCommand: ->
        command = ''
        command += @config.executablePath
        command += ' --level=' + @config.level
        command += ' --verbose'
        command += ' fix '
        command += @path

    # Process the data out of php-cs-fixer
    # @param err    Any errors occured via exec
    # @param stdout Overall standard output
    # @param stderr Overall standard errors
    process: (error, stdout, stderr) ->
        pattern = /.*(.+?)\) (.*) (\(.*\))/g
        errorList = []
        while (line = pattern.exec(stdout)) isnt null
            item = [0, "Fixed: " + line[3]]
            errorList.push item
        return errorList

module.exports = {Shell, PhpcsCommand, LinterCommand, PhpcsFixerCommand, MessDetectorCommand}
