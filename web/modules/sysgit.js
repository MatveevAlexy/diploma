'use strict';

const util = require('util');
const exec = util.promisify(require('child_process').exec);
const execFile = util.promisify(require('child_process').execFile);
const Emitter = require('./aevents.js');


async function execSysCommand(cmdstr, signal){
    let obj;
    try{
	obj  = await exec(cmdstr);
    } catch (exception){
	Emitter.emit('error', exception);
	return;
    }
    Emitter.emit(signal, obj);
}


async function execBashCommand(cmdstr, args, signal){
    let obj;
    try{
	obj  = await execFile(cmdstr, args);
    } catch (exception){
	Emitter.emit('error', exception);
	return;
    }
    Emitter.emit(signal, obj);
}




const test = () => {
    exec('ls -la', (error, stdout, stderr) => {
	if (error) {
	    console.error(`ls error: ${error}`);
	    return;
	}
	console.log(`stdout: ${stdout}`);
	console.error(`stderr: ${stderr}`);
    });
}

const init_repo = async function(name) {
    await execSysCommand(`ps -ax|grep ${name}`,'done');
}

const run_script_rdLAU = async function(arg,signal) {
    await execBashCommand('./rdLAU',arg,signal);
}

const run_script_brEXP = async function(arg,signal) {
    await execBashCommand('./brEXP',arg,signal);
}

const run_script_brTE = async function(arg,signal) {
    await execBashCommand('./brTE',arg,signal);
}

const run_script_brLAU = async function(arg,signal) {
    await execBashCommand('./brLAU',arg,signal);
}

const run_script_crtLAU = async function(arg,signal) {
    await execBashCommand('./crtLAU',arg,signal);
}

const run_script_crtTE = async function(arg,signal) {
    await execBashCommand('./crtTE',arg,signal);
}

const run_script_crtEXP = async function(arg,signal) {
    await execBashCommand('./crtEXP',arg,signal);
}

const run_script_crtUserDir = async function(arg,signal) {
    await execBashCommand('./crtUserDir',arg,signal);
}

module.exports = {test, init_repo, run_script_rdLAU, run_script_brEXP, run_script_brTE, run_script_brLAU,
        run_script_crtLAU, run_script_crtTE, run_script_crtEXP, run_script_crtUserDir};

