"use strict";
const {Pool} = require('pg')
const express = require('express');

const pool = new Pool({
    user: 'user_name',
    host: 'server_ip',
    database: 'r',
    password: 'password',
    port: 5432,
});
  
  
const app = express();
const urlencodedParser = express.urlencoded({extended: false});
app.set("view engine", "ejs");

app.get('/', function(req, res) {
    res.render('adm_auth.ejs');
});

app.post('/main', urlencodedParser, function(req, res) {
    var query = `SELECT * FROM users WHERE "user" = '${req.body.user}' AND pswd = '${req.body.pswd}';`
    pool.query(query, (err, user) => {
        if (user.rows[0] == undefined) {
                res.render('err.ejs');
        }
        if (user.rows[0].is_moder == 1) {
            user = user.rows[0].id;
            pool.query(`SELECT id from journal;`, (err, j_ids) => {
                j_ids = j_ids.rows;
                j_ids.sort(function(a, b){
                    return a.id - b.id;
                });
                res.render('adm_main.ejs', {j_ids: j_ids});
                main(user);
            });
        } else {
            res.render('err.ejs');
        }
    });
});

function main(user) {

app.post('/check', urlencodedParser, function(req, res) {
    var journal_id = req.body.journal_id;
    app.post('/posted', urlencodedParser, function(req, res) {
        var status = req.body.status;
        if (status == 1) {
            pool.query(`SELECT approve(${journal_id}, ${user});`);
        } else if (status == 2) {
            pool.query(`SELECT decline(${journal_id}, ${user});`);
        }
    });
    pool.query(`SELECT * FROM journal WHERE id = ${journal_id};`, (err, journal) => {
        if (journal == undefined) {
            res.render('err.ejs');
        }
        journal = journal.rows[0];
        if (journal.name_of_table == 'type_exp') {
            pool.query(`SELECT * FROM type_exp WHERE id = ${journal.foreign_id};`, (err, type_exp) => {
                type_exp = type_exp.rows[0];
                var new_type = JSON.parse(JSON.stringify(type_exp));
                if (journal.operation == 1) {
                    journal.col_set = journal.col_set.split(',');
                    journal.col_set[0] = journal.col_set[0].slice(1);
                    journal.col_set[journal.col_set.length-1] = journal.col_set[journal.col_set.length-1].slice(0, -1);
                    for (var j = 0; j < journal.col_set.length; j++) {
                        new_type[journal.col_set[j]] = journal.new_val_set[j];
                    }
                }
                pool.query(`SELECT "user" FROM users WHERE id = ${journal.user};`, (err, changer) =>{
                    changer = changer.rows[0].user;
                    pool.query(`SELECT "user" FROM users WHERE id = (SELECT "user" FROM journal WHERE foreign_id = ${journal.foreign_id} AND name_of_table = '${journal.name_of_table}' AND operation = 0);`, 
                            (err, creator) =>{
                        if (creator.rows[0] == undefined) {
                            creator = 'unknown';
                        } else {
                            creator = creator.rows[0].user;
                        }
                        res.render('adm_type.ejs', {journal: journal, new_type: new_type, type_exp: type_exp, changer: changer, creator: creator});
                    });
                });
            });
        } else if (journal.name_of_table == 'exp') {
            pool.query(`SELECT * FROM exp WHERE id = ${journal.foreign_id};`, (err, exp) => {
                exp = exp.rows[0];
                var new_exp = JSON.parse(JSON.stringify(exp));
                if (journal.operation == 1) {
                    journal.col_set = journal.col_set.split(',');
                    journal.col_set[0] = journal.col_set[0].slice(1);
                    journal.col_set[journal.col_set.length-1] = journal.col_set[journal.col_set.length-1].slice(0, -1);
                    for (var j = 0; j < journal.col_set.length; j++) {
                        new_exp[journal.col_set[j]] = journal.new_val_set[j];
                    }
                }
                pool.query(`SELECT * FROM type_exp WHERE id = ${exp.type_exp_id};`, (err, type_exp) => {
                    type_exp = type_exp.rows[0];
                    pool.query(`SELECT "user" FROM users WHERE id = ${journal.user};`, (err, changer) =>{
                        changer = changer.rows[0].user;
                        pool.query(`SELECT "user" FROM users WHERE id = (SELECT "user" FROM journal WHERE foreign_id = ${journal.foreign_id} AND name_of_table = '${journal.name_of_table}' AND operation = 0);`, 
                                (err, creator) =>{
                            if (creator.rows[0] == undefined) {
                                creator = 'unknown';
                            } else {
                                creator = creator.rows[0].user;
                            }
                            res.render('adm_exp.ejs', {journal: journal, new_exp: new_exp, type_exp: type_exp, exp: exp, changer: changer, creator: creator});
                        });
                    });
                });
            });
        } else if (journal.name_of_table == 'launch') {
            pool.query(`SELECT * FROM launch WHERE id = ${journal.foreign_id};`, (err, launch) => {
                launch = launch.rows[0];
                var new_launch = JSON.parse(JSON.stringify(launch));
                if (journal.operation == 1) {
                    journal.col_set = journal.col_set.split(',');
                    journal.col_set[0] = journal.col_set[0].slice(1);
                    journal.col_set[journal.col_set.length-1] = journal.col_set[journal.col_set.length-1].slice(0, -1);
                    for (var j = 0; j < journal.col_set.length; j++) {
                        new_launch[journal.col_set[j]] = journal.new_val_set[j];
                    }
                }
                pool.query(`SELECT * FROM exp WHERE id = ${launch.exp_id};`, (err, exp) => {
                    exp = exp.rows[0];
                    pool.query(`SELECT * FROM type_exp WHERE id = ${exp.type_exp_id};`, (err, type_exp) => {
                        type_exp = type_exp.rows[0];
                        pool.query(`SELECT "user" FROM users WHERE id = ${journal.user};`, (err, changer) =>{
                            changer = changer.rows[0].user;
                            pool.query(`SELECT "user" FROM users WHERE id = (SELECT "user" FROM journal WHERE foreign_id = ${journal.foreign_id} AND name_of_table = '${journal.name_of_table}' AND operation = 0);`, 
                                    (err, creator) =>{
                                if (creator.rows[0] == undefined) {
                                    creator = 'unknown';
                                } else {
                                    creator = creator.rows[0].user;
                                }
                                res.render('adm_launch.ejs', 
                                    {journal: journal, new_launch: new_launch, type_exp: type_exp, exp: exp, launch: launch, changer: changer, creator: creator});//exp не нужно?
                            });
                        });
                    });
                });
            });
        }
    });
});

app.post('/look', urlencodedParser, function(req, res) {
    var show_all = req.body.all
    if (show_all == 0) {
        pool.query(`SELECT * from journal WHERE state = 0;`, (err, journal) => {
            journal = journal.rows;
            journal.sort(function(a, b){
                return a.id - b.id;
            });
            res.render('adm_look.ejs', {journal: journal, show_all: show_all});
        });
    } else {
        pool.query(`SELECT * from journal;`, (err, journal) => {
            journal = journal.rows;
            journal.sort(function(a, b){
                return a.id - b.id;
            });
            res.render('adm_look.ejs', {journal: journal, show_all: show_all});
        });
    }
});

}

app.listen(8080, 'web_server_ip', () =>{
    console.log('Server started');
});