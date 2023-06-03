"use strict";
const { Pool } = require('pg')
const express = require('express');
const fileUpload = require('express-fileupload');
const sysgit = require('./modules/sysgit');
const { fileLoader } = require('ejs');
const session = require('express-session');




const pool = new Pool({
  user: 'user_name',
  host: 'server_ip',
  database: 'r',
  password: 'password',
  port: 5432,
})


const app = express();
const urlencodedParser = express.urlencoded({extended: false});
app.set("view engine", "ejs");

app.use(session({
  secret: 'keyboard cat',
  resave: false,
  saveUninitialized: true
}))

app.use(fileUpload());


app.get('/', function(req, res) {
  res.render('auth.ejs');
});

app.post('/main', urlencodedParser, function(req, res) {
  if (req.body.new_user == 1) {
    pool.query(`INSERT INTO users ("user", pswd) VALUES ($1, $2) RETURNING id;`, [req.body.user, req.body.pswd], (err, user) => {
      console.log(err);
      req.session.user_id = user.rows[0].id;
      res.render('main.ejs');
      main(req.session.user_id);
  });
  } else {
    var query = `SELECT id FROM users WHERE "user" = '${req.body.user}' AND pswd = '${req.body.pswd}';`
    pool.query(query, (err, user) => {
      req.session.user_id = user.rows[0].id;
      pool.query(`SELECT id, name from type_exp;`, (err, type_ids) => {
        req.session.type_ids = type_ids.rows;
        req.session.type_ids.sort(function(a, b){
          return a.id - b.id;
        });
        del_wrong_types(req, res, 0);
      });
  });
  }
});

function del_wrong_types(req, res, k) {
  if (k < req.session.type_ids.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [req.session.type_ids[k].id, req.session.user_id], (err, j_type) => {
      if (j_type.rows.length > 0) {
        req.session.type_ids.splice(k, 1);
        del_wrong_types(req, res, k);
      } else {
        del_wrong_types(req, res, k + 1);
      }
    });
  } else {
    pool.query(`SELECT id, exp_name from exp;`, (err, exp_ids) => {
      req.session.exp_ids = exp_ids.rows;
      req.session.exp_ids.sort(function(a, b){
        return a.id - b.id;
      });
      del_wrong_exps(req, res, 0);
    });
  }
}

function del_wrong_exps(req, res, k) {
  if (k < req.session.exp_ids.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [req.session.exp_ids[k].id, req.session.user_id], (err, j_exp) => {
      if (j_exp.rows.length > 0) {
        req.session.exp_ids.splice(k, 1);
        del_wrong_exps(req, res, k);
      } else {
        del_wrong_exps(req, res, k + 1);
      }
    });
  } else {
    pool.query(`SELECT id from launch;`, (err, launch_ids) => {
      req.session.launch_ids = launch_ids.rows;
      req.session.launch_ids.sort(function(a, b){
        return a.id - b.id;
      });
      del_wrong_launchs(req, res, 0);
    });
  }
}

function del_wrong_launchs(req, res, k) {
  if (k < req.session.launch_ids.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'launch' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [req.session.launch_ids[k].id, req.session.user_id], (err, j_launch) => {
      if (j_launch.rows.length > 0) {
        req.session.launch_ids.splice(k, 1);
        del_wrong_launchs(req, res, k);
      } else {
        del_wrong_launchs(req, res, k + 1);
      }
    });
  } else {
    res.render('main.ejs', {type_ids: req.session.type_ids, exp_ids: req.session.exp_ids, launch_ids: req.session.launch_ids});
    main();
  }
}

function main() {

  app.post("/download", urlencodedParser, function (req, res) {
    req.session.launch_id = req.body.launch_id;
    app.use(express.static('./gits'));
    pool.query(`SELECT exp_id FROM launch WHERE id = $1;`, [req.session.launch_id], (err, exp_id) => {
      req.session.exp_id = exp_id.rows[0].exp_id;
        pool.query(`SELECT type_exp_id FROM exp WHERE id = $1;`, [req.session.exp_id], (err, type_id) => {
          req.session.type_id = type_id.rows[0].type_exp_id;
          async function foo(req) {
            await sysgit.run_script_rdLAU(["./gits", `${req.session.user_id}`, `TE${req.session.type_id}`, `EXP${req.session.exp_id}`, `LAU${req.session.launch_id}`], 'done');
            res.render('download.ejs', {file_href: `/${req.session.user_id}/Algo500.data/TE${req.session.type_id}_EXP${req.session.exp_id}_LAU${req.session.launch_id}.zip`});
          }
          foo(req);
        });
    });
  })

app.post("/new_type", urlencodedParser, function (req, res) {
  req.session.n_pth = req.body.n_pth;
  req.session.n_ccond = req.body.n_ccond;
  req.session.n_vcond = req.body.n_vcond;
  req.session.n_result = req.body.n_result;
  res.render('type_new.ejs', {n_pth: req.session.n_pth, n_ccond: req.session.n_ccond, n_vcond: req.session.n_vcond, n_result: req.session.n_result});
  app.post("/new_type/posted", urlencodedParser, function (req, res) {
    if(!req.body) return res.sendStatus(400);
    const name = `"` + req.body.name + `"`;
    const goal = `"` + req.body.goal + `"`;
    var pth_str = ``;
    var ccond = ``;
    var vcond = ``;
    var result = ``;
    var query_str = `SELECT type_exp_new(CAST ('{"name", "goal"`;
    if (req.session.n_pth > 0) {
      query_str += `, "path_to_type"`;
      pth_str += `{"ref": "` + req.body[`pth_ref0`] + `", "name": "` + req.body[`pth_name0`] + `", "type": "` + req.body[`pth_type0`] + `"}`;
      for (var i = 1; i < req.session.n_pth; i++) {
        pth_str += `, {"ref": "` + req.body[`pth_ref${i}`] + `", "name": "` + req.body[`pth_name${i}`] + `", "type": "` + req.body[`pth_type${i}`] + `"}`;
      }
    }
    if (req.session.n_ccond > 0) {
      query_str += `, "ccond"`
      ccond += `"` + req.body[`ccond0`] + `", "` + req.body[`ccond_unit0`] + `"`;
      for (var i = 1; i < req.session.n_ccond; i++) {
        ccond += `, "` + req.body[`ccond${i}`] + `", "` + req.body[`ccond_unit${i}`] + `"`;
      }
    }
    if (req.session.n_vcond > 0) {
      query_str += `, "vcond"`
      vcond += `"` + req.body[`vcond0`] + `", "` + req.body[`vcond_unit0`] + `"`;
      for (var i = 1; i < req.session.n_vcond; i++) {
        vcond += `, "` + req.body[`vcond${i}`] + `", "` + req.body[`vcond_unit${i}`] + `"`;
      }
    }
    if (req.session.n_result > 0) {
      query_str += `, "result"`
      result += `"` + req.body[`result0`] + `", "` + req.body[`result_unit0`] + `"`;
      for (var i = 1; i < req.session.n_result; i++) {
        result += `, "` + req.body[`result${i}`] + `", "` + req.body[`result_unit${i}`] + `"`;
      }
    }
    query_str += `}' AS name[]), CAST ('[`;
    query_str += name + `, ` + goal;
    if (req.session.n_pth > 0) {
      query_str += `, [` + pth_str + `]`;
    }
    if (req.session.n_ccond > 0) {
      query_str += `, [` + ccond + `]`;
    }
    if (req.session.n_vcond > 0) {
      query_str += `, [` + vcond + `]`;
    }
    if (req.session.n_result > 0) {
      query_str += `, [` + result + `]`;
    }
    query_str += `]' AS jsonb), ${req.session.user_id});`;
    console.log(query_str);
    pool.query(query_str, (err, type_id) => {
      if(err) return console.log(err);
      type_id = type_id.rows[0].type_exp_new;
      async function foo(req) {
        await sysgit.run_script_crtTE(["./gits", `${req.session.user_id}`, `TE${type_id}`], 'done');
        var dir = `./gits/${req.session.user_id}/TE${type_id}/common/`;
        if (req.files != undefined) {
          if (req.files.gits.length != undefined) {
            for (var j = 0; j < req.files.gits.length; j++) {
              req.files.gits[j].mv(dir + req.files.gits[j].name);
            }
          } else {
            req.files.gits.mv(dir + req.files.gits.name);
          }
        }
        await sysgit.run_script_brTE(["./gits", `${req.session.user_id}`, `TE${req.session.type_id}`], 'done');
      }
      foo(req);
    });
  });
  
});

app.post("/upd_type", urlencodedParser, function (req, res) {
  req.session.type_id = req.body.type_id;
  req.session.ch_name = req.body.ch_name;
  req.session.ch_goal = req.body.ch_goal;
  req.session.ch_pth = req.body.ch_pth;
  req.session.ch_ccond = req.body.ch_ccond;
  req.session.ch_vcond = req.body.ch_vcond;
  req.session.ch_result = req.body.ch_result;
  req.session.n_pth = req.body.n_pth;
  pool.query(`SELECT ccond, vcond, result FROM type_exp WHERE id = ${req.session.type_id};`, (err, conds) => {
    req.session.ccond = conds.rows[0].ccond;
    req.session.vcond = conds.rows[0].vcond;
    req.session.result = conds.rows[0].result;
    if (req.session.ccond) {
      req.session.n_ccond = req.session.ccond.length / 2;
    } else {
      req.session.n_ccond = 0;
    }
    if (req.session.vcond) {
      req.session.n_vcond = req.session.vcond.length / 2;
    } else {
      req.session.n_vcond = 0;
    }
    if (req.session.result) {
      req.session.n_result = req.session.result.length / 2;
    } else {
      req.session.n_result = 0;
    }
    res.render('type_upd.ejs', {type_id: req.session.type_id, ch_name: req.session.ch_name, ch_goal: req.session.ch_goal, ch_pth: req.session.ch_pth, ch_ccond: req.session.ch_ccond, ch_vcond: req.session.ch_vcond, ch_result: req.session.ch_result, n_pth: req.session.n_pth, n_ccond: req.session.n_ccond, n_vcond: req.session.n_vcond, n_result: req.session.n_result, ccond: req.session.ccond, vcond: req.session.vcond, result: req.session.result});
    app.post("/upd_type/posted", urlencodedParser, function (req, res) {
      if(!req.body) return res.sendStatus(400);
      var pth_str = ``;
      var ccond = ``;
      var vcond = ``;
      var result = ``;
      var query_str = `SELECT type_exp_upd(` + req.session.type_id + `, CAST ('{`;
      if (req.session.ch_name == 1) {
        query_str += `"name", `;
      }
      if (req.session.ch_goal == 1) {
        query_str += `"goal", `;
      }
      if (req.session.ch_pth == 1) {
        query_str += `"path_to_type", `;
        pth_str += `{"ref": "` + req.body[`pth_ref0`] + `", "name": "` + req.body[`pth_name0`] + `", "type": "` + req.body[`pth_type0`] + `"}`;
        for (var i = 1; i < req.session.n_pth; i++) {
          pth_str += `, {"ref": "` + req.body[`pth_ref${i}`] + `", "name": "` + req.body[`pth_name${i}`] + `", "type": "` + req.body[`pth_type${i}`] + `"}`;
        }
      }
      if (req.session.ch_ccond == 1 && req.session.n_ccond > 0) {
        query_str += `"ccond", `
        ccond += `"` + req.body[`ccond0`] + `", "` + req.body[`ccond_unit0`] + `"`;
        for (var i = 1; i < req.session.n_ccond; i++) {
          ccond += `, "` + req.body[`ccond${i}`] + `", "` + req.body[`ccond_unit${i}`] + `"`;
        }
      }
      if (req.session.ch_vcond == 1 && req.session.n_vcond > 0) {
        query_str += `"vcond", `
        vcond += `"` + req.body[`vcond0`] + `", "` + req.body[`vcond_unit0`] + `"`;
        for (var i = 1; i < req.session.n_vcond; i++) {
          vcond += `, "` + req.body[`vcond${i}`] + `", "` + req.body[`vcond_unit${i}`] + `"`;
        }
      }
      if (req.session.ch_result == 1 && req.session.n_result > 0) {
        query_str += `"result", `
        result += `"` + req.body[`result0`] + `", "` + req.body[`result0`] + `"`;
        for (var i = 1; i < req.session.n_result; i++) {
          result += `, "` + req.body[`result${i}`] + `", "` + req.body[`result${i}`] + `"`;
        }
      }
      query_str = query_str.slice(0, -2);
      query_str += `}' AS name[]), CAST ('[`;
      if (req.session.ch_name == 1) {
        query_str += `"` + req.body.name + `", `;
      }
      if (req.session.ch_goal == 1) {
        query_str += `"` + req.body.goal + `", `;
      }
      if (req.session.ch_pth == 1) {
        query_str += `[` + pth_str + `], `;
      }
      if (req.session.ch_ccond == 1 && req.session.n_ccond > 0) {
        query_str += `[` + ccond + `], `;
      }
      if (req.session.ch_vcond == 1 && req.session.n_vcond > 0) {
        query_str += `[` + vcond + `], `;
      }
      if (req.session.ch_result == 1 && req.session.n_result > 0) {
        query_str += `[` + result + `], `;
      }
      query_str = query_str.slice(0, -2);
      query_str += `]' AS jsonb), ${req.session.user_id});`;
      console.log(query_str);
      pool.query(query_str, (err, launch) => {
        if(err) return console.log(err);
      });
    });
  });
});

app.post("/del_type", urlencodedParser, function (req, res) {
  req.session.type_id = req.body.type_id;
  query_str = `SELECT type_exp_del(${req.session.type_id}, ${req.session.user_id});`;
  console.log(query_str);
  pool.query(query_str, (err, launch) => {
    if(err) return console.log(err);
  });
});

app.post("/new_exp", urlencodedParser, function (req, res) {
  req.session.type_id = req.body.type_id;
  req.session.n_pth = req.body.n_pth;
  pool.query(`SELECT ccond FROM type_exp WHERE id = $1;`, [req.session.type_id], (err, conds) => {
    req.session.ccond = conds.rows[0].ccond;
    pool.query(`SELECT * from scomp;`, (err, scomps) => {
      req.session.scomps = scomps.rows;
      pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND user = $2 AND operation = 1 AND state = 0;`, [req.session.type_id, req.session.user_id], (err, upds) => {
        if (upds) {
          upds = upds.rows;
          var i = upds.findLastIndex(item => item.col_set.includes('ccond'));
          if (i != -1) {
            upds = upds[i];
            upds.col_set = upds.col_set.split(',');
            upds.col_set[0] = upds.col_set[0].slice(1);
            upds.col_set[upds.col_set.length-1] = upds.col_set[upds.col_set.length-1].slice(0, -1);
            req.session.ccond = upds.new_val_set[upds.col_set.findIndex(item => item == 'ccond')];
          }
        }
        if (req.session.ccond) {
          req.session.n_ccond = req.session.ccond.length / 2;
        } else {
          req.session.n_ccond = 0;
        }
        res.render('exp_new.ejs', {n_pth: req.session.n_pth, ccond: req.session.ccond, scomps: req.session.scomps});
        app.post("/new_exp/posted", urlencodedParser, function (req, res) {
          if(!req.body) return res.sendStatus(400);
          const name = `"` + req.body.name + `"`;
          const goal = `"` + req.body.goal + `"`;
          const sc_id = `${req.body.sc_id}`;
          var pth_str = ``;
          var ccond = ``;
          var query_str = `SELECT exp_new(CAST ('{"type_exp_id", "exp_name", "exp_goal", "sc_id"`;
          if (req.session.n_pth > 0) {
            query_str += `, "path_to_exp"`;
            pth_str += `{"ref": "` + req.body[`pth_ref0`] + `", "name": "` + req.body[`pth_name0`] + `", "type": "` + req.body[`pth_type0`] + `"}`;
            for (var i = 1; i < req.session.n_pth; i++) {
              pth_str += `, {"ref": "` + req.body[`pth_ref${i}`] + `", "name": "` + req.body[`pth_name${i}`] + `", "type": "` + req.body[`pth_type${i}`] + `"}`;
            }
          }
          if (req.session.n_ccond > 0) {
            query_str += `, "ccond"`
            ccond += `"` + req.body[`ccond0`] + `"`;
            for (var i = 1; i < req.session.n_ccond; i++) {
              ccond += `, "` + req.body[`ccond${i*2}`] + `"`;
            }
          }
          query_str += `}' AS name[]), CAST ('[`;
          query_str += `${req.session.type_id}, ` + name + `, ` + goal + `, ` + sc_id;
          if (req.session.n_pth > 0) {
            query_str += `, [` + pth_str + `]`;
          }
          if (req.session.n_ccond > 0) {
            query_str += `, [` + ccond + `]`;
          }
          query_str += `]' AS jsonb), ${req.session.user_id});`;
          console.log(query_str);
          pool.query(query_str, (err, exp_id) => {
            if(err) return console.log(err);
            req.session.exp_id = exp_id.rows[0].exp_new;
            async function foo(req) {
              await sysgit.run_script_crtEXP(["./gits", `${req.session.user_id}`, `TE${req.session.type_id}`, `EXP${req.session.exp_id}`], 'done');
              var dir = `./gits/${req.session.user_id}/Algo500.data/TE${req.session.type_id}/EXP${req.session.exp_id}/`;
              if (req.files != undefined) {
                if (req.files.gits.length != undefined) {
                  for (var j = 0; j < req.files.gits.length; j++) {
                    req.files.gits[j].mv(dir + req.files.gits[j].name);
                  }
                } else {
                  req.files.gits.mv(dir + req.files.gits.name);
                }
              }
              await sysgit.run_script_brEXP(["./gits", `${req.session.user_id}`, `TE${req.session.type_id}`, `EXP${req.session.exp_id}`], 'done');
            }
            foo(req);
          });
        });
      });
    });
  });
});

app.post("/upd_exp", urlencodedParser, function (req, res) {
  req.session.exp_id = req.body.exp_id;
  req.session.ch_name = req.body.ch_name;
  req.session.ch_goal = req.body.ch_goal;
  req.session.ch_sc = req.body.ch_sc;
  req.session.ch_pth = req.body.ch_pth;
  req.session.ch_ccond = req.body.ch_ccond;
  req.session.n_pth = req.body.n_pth;
  pool.query(`SELECT type_exp_id FROM exp WHERE id = $1;`, [req.session.exp_id], (err, type) => {
    req.session.type_id = type.rows[0].type_exp_id;
      pool.query(`SELECT ccond FROM type_exp WHERE id = $1;`, [req.session.type_id], (err, conds) => {
        req.session.ccond = conds.rows[0].ccond;
      pool.query(`SELECT * from scomp;`, (err, scomps) => {
        req.session.scomps = scomps.rows;
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND user = $2 AND operation = 1 AND state = 0;`, [req.session.type_id, req.session.user_id], (err, upds) => {
          if (upds) {
            upds = upds.rows;
            var i = upds.findLastIndex(item => item.col_set.includes('ccond'));
            if (i != -1) {
              upds = upds[i];
              upds.col_set = upds.col_set.split(',');
              upds.col_set[0] = upds.col_set[0].slice(1);
              upds.col_set[upds.col_set.length-1] = upds.col_set[upds.col_set.length-1].slice(0, -1);
              req.session.ccond = upds.new_val_set[upds.col_set.findIndex(item => item == 'ccond')];
            }
          }
          if (req.session.ccond) {
            req.session.n_ccond = req.session.ccond.length / 2;
          } else {
            req.session.n_ccond = 0;
          }
          res.render('exp_upd.ejs', {ch_name: req.session.ch_name, ch_goal: req.session.ch_goal, ch_sc: req.session.ch_sc, ch_pth: req.session.ch_pth, ch_ccond: req.session.ch_ccond, n_pth: req.session.n_pth, ccond: req.session.ccond, scomps: req.session.scomps});
          app.post("/upd_exp/posted", urlencodedParser, function (req, res) {
            if(!req.body) return res.sendStatus(400);
            var pth_str = ``;
            var ccond = ``;
            var query_str = `SELECT exp_upd(` + req.session.exp_id + `, CAST ('{`;
            if (req.session.ch_name == 1) {
              query_str += `"exp_name", `;
            }
            if (req.session.ch_goal == 1) {
              query_str += `"exp_goal", `;
            }
            if (req.session.ch_sc == 1) {
              query_str += `"sc_id", `;
            }
            if (req.session.ch_pth == 1 && req.session.n_pth > 0) {
              query_str += `"path_to_exp", `;
              pth_str += `{"ref": "` + req.body[`pth_ref0`] + `", "name": "` + req.body[`pth_name0`] + `", "type": "` + req.body[`pth_type0`] + `"}`;
              for (var i = 1; i < req.session.n_pth; i++) {
                pth_str += `, {"ref": "` + req.body[`pth_ref${i}`] + `", "name": "` + req.body[`pth_name${i}`] + `", "type": "` + req.body[`pth_type${i}`] + `"}`;
              }
            }
            if (req.session.ch_ccond == 1 && req.session.n_ccond > 0) {
              query_str += `"ccond", `
              ccond += `"` + req.body[`ccond0`] + `"`;
              for (var i = 1; i < req.session.n_ccond; i++) {
                ccond += `, "` + req.body[`ccond${i * 2}`] + `"`;
              }
            }
            query_str = query_str.slice(0, -2);
            query_str += `}' AS name[]), CAST ('[`;
            if (req.session.ch_name == 1) {
              query_str += `"` + req.body.name + `", `;
            }
            if (req.session.ch_goal == 1) {
              query_str += `"` + req.body.goal + `", `;
            }
            if (req.session.ch_sc == 1) {
              query_str += `${req.body.sc_id}, `;
            }
            if (req.session.ch_pth == 1) {
              query_str += `[` + pth_str + `], `;
            }
            if (req.session.ch_ccond == 1 && req.session.n_ccond > 0) {
              query_str += `[` + ccond + `], `;
            }
            query_str = query_str.slice(0, -2);
            query_str += `]' AS jsonb), ${req.session.user_id});`;
            console.log(query_str);
            pool.query(query_str, (err, no) => {
              if (err) return console.log(err);
            });
          });
        });
      });
    });
  });
});

app.post("/del_exp", urlencodedParser, function (req, res) {
  req.session.exp_id = req.body.exp_id;
  var query_str = `SELECT exp_del(${req.session.exp_id}, ${req.session.user_id});`;
  console.log(query_str);
  pool.query(query_str, (err, launch) => {
    if(err) return console.log(err);
  });
});

app.post("/new_launch", urlencodedParser, function (req, res) {
  req.session.exp_id = req.body.exp_id;
  pool.query(`SELECT type_exp_id FROM exp WHERE id = $1;`, [req.session.exp_id], (err, type_id) => {
    req.session.type_id = type_id.rows[0].type_exp_id;
    pool.query(`SELECT vcond, result FROM type_exp WHERE id = $1;`, [req.session.type_id], (err, conds) => {
      req.session.vcond = conds.rows[0].vcond;
      req.session.result = conds.rows[0].result;
      pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND user = $2 AND operation = 1 AND state = 0;`, [req.session.type_id, req.session.user_id], (err, upds) => {
        if (upds) {
          upds = upds.rows;
          var i = upds.findLastIndex(item => item.col_set.includes('vcond'));
          if (i != -1) {
            var type_vcond = upds[i];
            type_vcond.col_set = type_vcond.col_set.split(',');
            type_vcond.col_set[0] = type_vcond.col_set[0].slice(1);
            type_vcond.col_set[type_vcond.col_set.length-1] = type_vcond.col_set[type_vcond.col_set.length-1].slice(0, -1);
            req.session.vcond = type_vcond.new_val_set[type_vcond.col_set.findIndex(item => item == 'vcond')];
          }
          var j = upds.findLastIndex(item => item.col_set.includes('result'));
          if (j != -1) {
            if (j != i) {
              upds = upds[i];
              upds.col_set = upds.col_set.split(',');
              upds.col_set[0] = upds.col_set[0].slice(1);
              upds.col_set[upds.col_set.length-1] = upds.col_set[upds.col_set.length-1].slice(0, -1);
            } else {
              upds = type_vcond;
            }
            req.session.result = upds.new_val_set[upds.col_set.findIndex(item => item == 'result')];
          }
        }
        if (req.session.vcond) {
          req.session.n_vcond = req.session.vcond.length / 2;
        } else {
          req.session.n_vcond = 0;
        }
        if (req.session.result) {
          req.session.n_result = req.session.result.length / 2;
        } else {
          req.session.n_result = 0;
        }
        res.render('launch_new.ejs', {vcond: req.session.vcond, result: req.session.result});
        app.post("/new_launch/posted", urlencodedParser, function (req, res) {
          if(!req.body) return res.sendStatus(400);
          var vcond = ``;
          var result = ``;
          var query_str = `SELECT launch_new(CAST ('{"exp_id", `;
          if (req.session.n_vcond > 0) {
            query_str += `"vcond", `
            vcond += `"` + req.body[`vcond0`] + `"`;
            for (var i = 1; i < req.session.n_vcond; i++) {
              vcond += `, "` + req.body[`vcond${i * 2}`] + `"`;
            }
          }
          query_str += `"result"`
          result += `"` + req.body[`result0`] + `"`;
          for (var i = 1; i < req.session.n_result; i++) {
            result += `, "` + req.body[`result${i* 2}`] + `"`;
          }
          query_str += `}' AS name[]), CAST ('[${req.session.exp_id}`;
          if (req.session.n_vcond > 0) {
            query_str += `, [` + vcond + `]`;
          }
          query_str += `, [` + result + `]`;
          query_str += `]' AS jsonb), ${req.session.user_id});`;
          console.log(query_str);
          pool.query(query_str, (err, launch_id) => {
            if(err) return console.log(err);
            req.session.launch_id = launch_id.rows[0].launch_new;
            async function foo(req) {
              await sysgit.run_script_crtLAU(["./gits", `${req.session.user_id}`, `TE${req.session.type_id}`, `EXP${req.session.exp_id}`, `LAU${req.session.launch_id}`], 'done');
              var dir = `./gits/${req.session.user_id}/Algo500.data/TE${req.session.type_id}/EXP${req.session.exp_id}/LAU${req.session.launch_id}/`;
              if (req.files != undefined) {
                if (req.files.gits.length != undefined) {
                  for (var j = 0; j < req.files.gits.length; j++) {
                    req.files.gits[j].mv(dir + req.files.gits[j].name);
                  }
                } else {
                  req.files.gits.mv(dir + req.files.gits.name);
                }
              }
              await sysgit.run_script_brLAU(["./gits", `${req.session.user_id}`, `TE${req.session.type_id}`, `EXP${req.session.exp_id}`, `LAU${req.session.launch_id}`], 'done');
            }
            foo(req);
          });
        });
      });
    });
  });
});

app.post("/upd_launch", urlencodedParser, function (req, res) {
  req.session.launch_id = req.body.launch_id;
  req.session.ch_vcond = req.body.ch_vcond;
  req.session.ch_result = req.body.ch_result;
  pool.query(`SELECT exp_id FROM launch WHERE id = $1;`, [req.session.launch_id], (err, exp_id) => {
    req.session.exp_id = exp_id.rows[0].exp_id;
    pool.query(`SELECT type_exp_id FROM exp WHERE id = $1;`, [req.session.exp_id], (err, type_exp_id) => {
      req.session.type_id = type_exp_id.rows[0].type_exp_id;
      pool.query(`SELECT vcond, result FROM type_exp WHERE id = $1;`, [req.session.type_id], (err, conds) => {
        req.session.vcond = conds.rows[0].vcond;
        req.session.result = conds.rows[0].result;
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND "user" = $2 AND operation = 1 AND state = 0;`, [req.session.type_id, req.session.user_id], (err, upds) => {
          if (upds) {
            upds = upds.rows;
            var i = upds.findLastIndex(item => item.col_set.includes('vcond'));
            if (i != -1) {
              var type_vcond = upds[i];
              type_vcond.col_set = type_vcond.col_set.split(',');
              type_vcond.col_set[0] = type_vcond.col_set[0].slice(1);
              type_vcond.col_set[type_vcond.col_set.length-1] = type_vcond.col_set[type_vcond.col_set.length-1].slice(0, -1);
              req.session.vcond = type_vcond.new_val_set[type_vcond.col_set.findIndex(item => item == 'vcond')];
            }
            var j = upds.findLastIndex(item => item.col_set.includes('result'));
            if (j != -1) {
              if (j != i) {
                upds = upds[i];
                upds.col_set = upds.col_set.split(',');
                upds.col_set[0] = upds.col_set[0].slice(1);
                upds.col_set[upds.col_set.length-1] = upds.col_set[upds.col_set.length-1].slice(0, -1);
              } else {
                upds = type_vcond;
              }
              req.session.result = upds.new_val_set[upds.col_set.findIndex(item => item == 'result')];
            }
          }
          if (req.session.vcond) {
            req.session.n_vcond = req.session.vcond.length / 2;
          } else {
            req.session.n_vcond = 0;
          }
          if (req.session.result) {
            req.session.n_result = req.session.result.length / 2;
          } else {
            req.session.n_result = 0;
          }
          res.render('launch_upd.ejs', {vcond: req.session.vcond, result: req.session.result, ch_vcond: req.session.ch_vcond, ch_result: req.session.ch_result});
          app.post("/upd_launch/posted", urlencodedParser, function (req, res) {
            if(!req.body) return res.sendStatus(400);
            var vcond = ``;
            var result = ``;
            var query_str = `SELECT launch_upd(${req.session.launch_id}, CAST ('{`;
            if (req.session.ch_vcond == 1 && req.session.n_vcond > 0) {
              query_str += `"vcond"`
              vcond += `"` + req.body[`vcond0`] + `"`;
              for (var i = 1; i < req.session.n_vcond; i++) {
                vcond += `, "` + req.body[`vcond${i * 2}`] + `"`;
              }
            }
            if (req.session.ch_result == 1 && req.session.n_result > 0) {
              if (req.session.ch_vcond == 1 && req.session.n_vcond > 0) {
                query_str += `, "result"`;
              } else {
                query_str += `"result"`;
              }
              result += `"` + req.body[`result0`] + `"`;
              for (var i = 1; i < req.session.n_result; i++) {
                result += `, "` + req.body[`result${i * 2}`] + `"`;
              }
            }
            query_str += `}' AS name[]), CAST ('[`;
            if (req.session.ch_vcond == 1 && req.session.n_vcond > 0) {
              query_str += `[` + vcond + `]`;
            }
            if (req.session.ch_result == 1 && req.session.n_result > 0) {
              if (req.session.ch_vcond == 1) {
                query_str += `, [` + result + `]`;
              } else {
                query_str += `[` + result + `]`;
              }
            }
            query_str += `]' AS jsonb), ${req.session.user_id});`;
            console.log(query_str);
            pool.query(query_str, (err, no) => {
              if(err) return console.log(err);
              async function foo(req) {
                await sysgit.run_script_crtLAU(["./gits", `${req.session.user_id}`, `TE${req.session.type_id}`, `EXP${req.session.exp_id}`, `LAU${req.session.launch_id}`], 'done');
                var dir = `./gits/${req.session.user_id}/Algo500.data/TE${req.session.type_id}/EXP${req.session.exp_id}/LAU${req.session.launch_id}/`;
                if (req.files.gits.length != undefined) {
                  for (var j = 0; j < req.files.gits.length; j++) {
                    req.files.gits[j].mv(dir + req.files.gits[j].name);
                  }
                } else {
                  req.files.gits.mv(dir + req.files.gits.name);
                }
                await sysgit.run_script_brLAU(["./gits", `${req.session.user_id}`, `TE${req.session.type_id}`, `EXP${req.session.exp_id}`, `LAU${req.session.launch_id}`], 'done');
              }
              if (req.files != undefined) {
                foo(req);
              }
            });
          });
        });
      });
    });
  });
});

app.post("/del_launch", urlencodedParser, function (req, res) {
  req.session.launch_id = req.body.launch_id;
  var query_str = `SELECT launch_del(${req.session.launch_id}, ${req.session.user_id});`;
  console.log(query_str);
  pool.query(query_str, (err, launch) => {
    if(err) return console.log(err);
  });
});

app.post("/type_ids", urlencodedParser, function (req, res) {
  pool.query(`SELECT * from type_exp;`, (err, types) => {
    req.session.types = types.rows;
    req.session.types.sort(function(a, b){
      return a.id - b.id;
    });
    checkType(req, res, pool, 0);
  });
});

function checkType(req, res, pool, k) {
  if (k < req.session.types.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [req.session.types[k].id, req.session.user_id], (err, j_type) => {
      if (j_type.rows.length > 0) {
        req.session.types.splice(k, 1);
        checkType(req, res, pool, k);
      } else {
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND "user" = $2 AND operation = 1 AND state = 0;`, [types[k].id, req.session.user_id], (err, j_type) => {
          j_type = j_type.rows;
          for(var i = 0; i < j_type.length; i++) {
            j_type[i].col_set = j_type[i].col_set.split(',');
            j_type[i].col_set[0] = j_type[i].col_set[0].slice(1);
            j_type[i].col_set[j_type[i].col_set.length-1] = j_type[i].col_set[j_type[i].col_set.length-1].slice(0, -1);
            for (var j = 0; j < j_type[i].col_set.length; j++) {
              req.session.types[k][j_type[i].col_set[j]] = j_type[i].new_val_set[j];
            }
          }
          k++;
          checkType(req, res, pool, k);
        });
      }
    });
  } else {
    res.render('type_ids.ejs', {types: req.session.types});
  }
}

app.post("/look", urlencodedParser, function (req, res) {
  req.session.type_id = req.body.type_id;
  req.session.show_id = req.body.show_id;
    pool.query(`SELECT * from type_exp WHERE id = $1;`, [req.session.type_id], (err, type) => {
      req.session.type = type;
      pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
      [req.session.type_id, req.session.user_id], (err, j_type) => {
        if (err) console.log(err);
        if (j_type.rows != undefined && j_type.rows.length > 0) {
          req.session.type = [];
        } else {
          req.session.type = req.session.type.rows[0];
        }
        if (req.session.type.length == 0) {
          res.render('empty.ejs', {});
        }
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND "user" = $2 AND operation = 1 AND state = 0;`, [req.session.type_id, req.session.user_id], (err, j_type) => {
          j_type = j_type.rows;
          j_type.sort(function(a, b){
            return a.id - b.id;
          });
          for (var i = 0; i < j_type.length; i++) {
            j_type[i].col_set = j_type[i].col_set.split(',');
            j_type[i].col_set[0] = j_type[i].col_set[0].slice(1);
            j_type[i].col_set[j_type[i].col_set.length-1] = j_type[i].col_set[j_type[i].col_set.length-1].slice(0, -1);
            for (var j = 0; j < j_type[i].col_set.length; j++) {
              req.session.type[j_type[i].col_set[j]] = j_type[i].new_val_set[j];
            }
          }
          pool.query(`SELECT * from exp WHERE type_exp_id = $1;`, [req.session.type_id], (err, exp) => {
            req.session.exp = exp.rows;
            req.session.exp.sort(function(a, b){
              return a.id - b.id;
            });
            checkExp(req, res, pool, 0);
          });
        });
      });
    });
});

function checkExp(req, res, pool, k) {
  if (k < req.session.exp.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [req.session.exp[k].id, req.session.user_id], (err, j_exp) => {
      if (j_exp.rows != undefined && j_exp.rows.length > 0) {
        req.session.exp.splice(k, 1);
        checkExp(req, res, pool, k);
      } else {
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'exp' AND "user" = $2 AND operation = 1 AND state = 0;`, [req.session.exp[k].id, req.session.user_id], (err, j_exp) => {
          j_exp = j_exp.rows;
          j_exp.sort(function(a, b){
            return a.id - b.id;
          });
          for (var i = 0; i < j_exp.length; i++) {
            j_exp[i].col_set = j_exp[i].col_set.split(',');
            j_exp[i].col_set[0] = j_exp[i].col_set[0].slice(1);
            j_exp[i].col_set[j_exp[i].col_set.length-1] = j_exp[i].col_set[j_exp[i].col_set.length-1].slice(0, -1);
            for (var j = 0; j < j_exp[i].col_set.length; j++) {
              req.session.exp[k][j_exp[i].col_set[j]] = j_exp[i].new_val_set[j];
            }
          }
          k++;
          checkExp(req, res, pool, k);
        });
      }
    });
  } else {
    req.session.launches = [];
    req.session.exp_num = [];
    goThroughLaunches(req, res, pool, 0);
  }
}

function goThroughLaunches(req, res, pool, i) {
  if (i < req.session.exp.length) {
    pool.query(`SELECT * from launch WHERE exp_id = $1;`, [req.session.exp[i].id], (err, launch) => {
      launch = launch.rows;
      launch.sort(function(a, b){
        return a.id - b.id;
      });
      for (var j = 0; j < launch.length; j++) {
        req.session.launches.push(launch[j]);
        req.session.exp_num.push(i);
      }
      goThroughLaunches(req, res, pool, i + 1);
    });
  } else {
    checkLaunch(req, res, pool, 0);
  }
}

function checkLaunch(req, res, pool, k) {
  if (k < req.session.launches.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'launch' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [req.session.launches[k].id, req.session.user_id], (err, j_launch) => {
        if (err) console.log(err);
        if (j_launch.rows != undefined && j_launch.rows.length > 0) {
          req.session.launches.splice(k, 1);
        checkLaunch(req, res, pool, k);
      } else {
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'launch' AND "user" = $2 AND operation = 1 AND state = 0;`, [req.session.launches[k].id, req.session.user_id], (err, j_launch) => {
          j_launch = j_launch.rows;
          for (var i = 0; i < j_launch.length; i++) {
            j_launch[i].col_set = j_launch[i].col_set.split(',');
            j_launch[i].col_set[0] = j_launch[i].col_set[0].slice(1);
            j_launch[i].col_set[j_launch[i].col_set.length-1] = j_launch[i].col_set[j_launch[i].col_set.length-1].slice(0, -1);
            for (var j = 0; j < j_launch[i].col_set.length; j++) {
              req.session.launches[k][j_launch[i].col_set[j]] = j_launch[i].new_val_set[j];
            }
          }
          k++;
          checkLaunch(req, res, pool, k);
        });
      }
    });
  } else {
    pool.query(`SELECT * FROM scomp;`, (err, scomps) => {
      req.session.scomps = scomps.rows;
      req.session.scomps.sort(function(a, b){
        return a.id - b.id;
      });
      res.render('table.ejs', {type_id: req.session.type_id, type: req.session.type, exp: req.session.exp, launch: req.session.launches, exp_num: req.session.exp_num, show_id: req.session.show_id, scomps: req.session.scomps});
    });
  }
}

}



app.listen(8000, 'web_server_ip', () =>{
  console.log('Server started');
});