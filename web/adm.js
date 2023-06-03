"use strict";
const {Pool} = require('pg')
const express = require('express');
const session = require('express-session');

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

app.use(session({
    secret: 'keyboard cat',
    resave: false,
    saveUninitialized: true
  }))

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
            req.session.user_id = user.rows[0].id;
            pool.query(`SELECT id from journal;`, (err, j_ids) => {
                req.session.j_ids = j_ids.rows;
                req.session.j_ids.sort(function(a, b){
                    return a.id - b.id;
                });
                res.render('adm_main.ejs', {j_ids: req.session.j_ids});
                main();
            });
        } else {
            res.render('err.ejs');
        }
    });
});

function main() {

app.post('/check', urlencodedParser, function(req, res) {
    req.session.journal_id = req.body.journal_id;
    app.post('/posted', urlencodedParser, function(req, res) {
        req.session.status = req.body.status;
        if (req.session.status == 1) {
            //pool.query(`SELECT approve(${req.session.journal_id}, ${req.session.user_id});`);
        } else if (req.session.status == 2) {
            //pool.query(`SELECT decline(${req.session.journal_id}, ${req.session.user_id});`);
        }
    });
    pool.query(`SELECT * FROM journal WHERE id = ${req.session.journal_id};`, (err, journal) => {
        if (journal == undefined) {
            res.render('err.ejs');
        }
        req.session.journal = journal.rows[0];
        if (req.session.journal.name_of_table == 'type_exp') {
            pool.query(`SELECT * FROM type_exp WHERE id = ${req.session.journal.foreign_id};`, (err, type_exp) => {
                req.session.type_exp = type_exp.rows[0];
                req.session.new_type = JSON.parse(JSON.stringify(req.session.type_exp));
                if (req.session.journal.operation == 1) {
                    req.session.journal.col_set = req.session.journal.col_set.split(',');
                    req.session.journal.col_set[0] = req.session.journal.col_set[0].slice(1);
                    req.session.journal.col_set[req.session.journal.col_set.length-1] = req.session.journal.col_set[req.session.journal.col_set.length-1].slice(0, -1);
                    for (var j = 0; j < req.session.journal.col_set.length; j++) {
                        req.session.new_type[req.session.journal.col_set[j]] = req.session.journal.new_val_set[j];
                    }
                }
                pool.query(`SELECT "user" FROM users WHERE id = ${req.session.journal.user};`, (err, changer) =>{
                    req.session.changer = changer.rows[0].user;
                    pool.query(`SELECT "user" FROM users WHERE id = (SELECT "user" FROM journal WHERE foreign_id = ${req.session.journal.foreign_id} AND name_of_table = '${req.session.journal.name_of_table}' AND operation = 0);`, 
                            (err, creator) =>{
                        if (creator.rows[0] == undefined) {
                            req.session.creator = 'unknown';
                        } else {
                            req.session.creator = creator.rows[0].user;
                        }
                        res.render('adm_type.ejs', {journal: req.session.journal, new_type: req.session.new_type, type_exp: req.session.type_exp, changer: req.session.changer, creator: req.session.creator});
                    });
                });
            });
        } else if (req.session.journal.name_of_table == 'exp') {
            pool.query(`SELECT * FROM exp WHERE id = ${req.session.journal.foreign_id};`, (err, exp) => {
                req.session.exp = exp.rows[0];
                req.session.new_exp = JSON.parse(JSON.stringify(req.session.exp));
                if (req.session.journal.operation == 1) {
                    req.session.journal.col_set = req.session.journal.col_set.split(',');
                    req.session.journal.col_set[0] = req.session.journal.col_set[0].slice(1);
                    req.session.journal.col_set[req.session.journal.col_set.length-1] = req.session.journal.col_set[req.session.journal.col_set.length-1].slice(0, -1);
                    for (var j = 0; j < req.session.journal.col_set.length; j++) {
                        req.session.new_exp[req.session.journal.col_set[j]] = req.session.journal.new_val_set[j];
                    }
                }
                pool.query(`SELECT * FROM type_exp WHERE id = ${req.session.exp.type_exp_id};`, (err, type_exp) => {
                    req.session.type_exp = type_exp.rows[0];
                    pool.query(`SELECT "user" FROM users WHERE id = ${req.session.journal.user};`, (err, changer) =>{
                        req.session.changer = changer.rows[0].user;
                        pool.query(`SELECT "user" FROM users WHERE id = (SELECT "user" FROM journal WHERE foreign_id = ${req.session.journal.foreign_id} AND name_of_table = '${req.session.journal.name_of_table}' AND operation = 0);`, 
                                (err, creator) =>{
                            if (creator.rows[0] == undefined) {
                                req.session.creator = 'unknown';
                            } else {
                                req.session.creator = creator.rows[0].user;
                            }
                            res.render('adm_exp.ejs', {journal: req.session.journal, new_exp: req.session.new_exp, type_exp: req.session.type_exp, exp: req.session.exp, changer: req.session.changer, creator: req.session.creator});
                        });
                    });
                });
            });
        } else if (req.session.journal.name_of_table == 'launch') {
            pool.query(`SELECT * FROM launch WHERE id = ${req.session.journal.foreign_id};`, (err, launch) => {
                req.session.launch = launch.rows[0];
                req.session.new_launch = JSON.parse(JSON.stringify(req.session.launch));
                if (req.session.journal.operation == 1) {
                    req.session.journal.col_set = req.session.journal.col_set.split(',');
                    req.session.journal.col_set[0] = req.session.journal.col_set[0].slice(1);
                    req.session.journal.col_set[req.session.journal.col_set.length-1] = req.session.journal.col_set[req.session.journal.col_set.length-1].slice(0, -1);
                    for (var j = 0; j < req.session.journal.col_set.length; j++) {
                        req.session.new_launch[req.session.journal.col_set[j]] = req.session.journal.new_val_set[j];
                    }
                }
                pool.query(`SELECT * FROM exp WHERE id = ${req.session.launch.exp_id};`, (err, exp) => {
                    req.session.exp = exp.rows[0];
                    pool.query(`SELECT * FROM type_exp WHERE id = ${req.session.exp.type_exp_id};`, (err, type_exp) => {
                        req.session.type_exp = type_exp.rows[0];
                        pool.query(`SELECT "user" FROM users WHERE id = ${req.session.journal.user};`, (err, changer) =>{
                            req.session.changer = changer.rows[0].user;
                            pool.query(`SELECT "user" FROM users WHERE id = (SELECT "user" FROM journal WHERE foreign_id = ${req.session.journal.foreign_id} AND name_of_table = '${req.session.journal.name_of_table}' AND operation = 0);`, 
                                    (err, creator) =>{
                                if (creator.rows[0] == undefined) {
                                    req.session.creator = 'unknown';
                                } else {
                                    req.session.creator = creator.rows[0].user;
                                }
                                res.render('adm_launch.ejs', 
                                    {journal: req.session.journal, new_launch: req.session.new_launch, type_exp: req.session.type_exp, exp: req.session.exp, launch: req.session.launch, changer: req.session.changer, creator: req.session.creator});
                            });
                        });
                    });
                });
            });
        }
    });
});

app.post('/look', urlencodedParser, function(req, res) {
    req.session.show_all = req.body.all
    if (req.session.show_all == 0) {
        pool.query(`SELECT * from journal WHERE state = 0;`, (err, journal) => {
            req.session.journal = journal.rows;
            req.session.journal.sort(function(a, b){
                return a.id - b.id;
            });
            res.render('adm_look.ejs', {journal: req.session.journal, show_all: req.session.show_all});
        });
    } else {
        pool.query(`SELECT * from journal;`, (err, journal) => {
            req.session.journal = journal.rows;
            req.session.journal.sort(function(a, b){
                return a.id - b.id;
            });
            res.render('adm_look.ejs', {journal: req.session.journal, show_all: req.session.show_all});
        });
    }
});

}

app.listen(8080, 'web_server_ip', () =>{
    console.log('Server started');
});