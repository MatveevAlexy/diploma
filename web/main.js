"use strict";
const { Pool } = require('pg')
const express = require('express');
const fileUpload = require('express-fileupload');
const sysgit = require('./modules/sysgit');
const { fileLoader } = require('ejs');

//const bodyParser = require('body-parser');


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

app.use(fileUpload());
/*app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));*/

app.get('/', function(req, res) {
  res.render('auth.ejs');
});

app.post('/main', urlencodedParser, function(req, res) {
  if (req.body.new_user == 1) {
    pool.query(`INSERT INTO users ("user", pswd) VALUES ($1, $2) RETURNING id;`, [req.body.user, req.body.pswd], (err, user) => {
      console.log(err);
      user = user.rows[0].id;
      res.render('main.ejs');
      main(user);
  });
  } else {
    var query = `SELECT id FROM users WHERE "user" = '${req.body.user}' AND pswd = '${req.body.pswd}';`
    pool.query(query, (err, user) => {
      user = user.rows[0].id;
      pool.query(`SELECT id, name from type_exp;`, (err, type_ids) => {
        type_ids = type_ids.rows;
        type_ids.sort(function(a, b){
          return a.id - b.id;
        });
        del_wrong_types(res, type_ids, user, 0);
      });
  });
  }
});

function del_wrong_types(res, type_ids, user, k) {
  if (k < type_ids.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [type_ids[k].id, user], (err, j_type) => {
      if (j_type.rows.length > 0) {
        type_ids.splice(k, 1);
        del_wrong_types(res, type_ids, user, k);
      } else {
        del_wrong_types(res, type_ids, user, k + 1);
      }
    });
  } else {
    pool.query(`SELECT id, exp_name from exp;`, (err, exp_ids) => {
      exp_ids = exp_ids.rows;
      exp_ids.sort(function(a, b){
        return a.id - b.id;
      });
      del_wrong_exps(res, type_ids, exp_ids, user, 0);
    });
  }
}

function del_wrong_exps(res, type_ids, exp_ids, user, k) {
  if (k < exp_ids.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [exp_ids[k].id, user], (err, j_exp) => {
      if (j_exp.rows.length > 0) {
        exp_ids.splice(k, 1);
        del_wrong_exps(res, type_ids, exp_ids, user, k);
      } else {
        del_wrong_exps(res, type_ids, exp_ids, user, k + 1);
      }
    });
  } else {
    pool.query(`SELECT id from launch;`, (err, launch_ids) => {
      launch_ids = launch_ids.rows;
      launch_ids.sort(function(a, b){
        return a.id - b.id;
      });
      del_wrong_launchs(res, type_ids, exp_ids, launch_ids, user, 0);
    });
  }
}

function del_wrong_launchs(res, type_ids, exp_ids, launch_ids, user, k) {
  if (k < launch_ids.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'launch' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [launch_ids[k].id, user], (err, j_launch) => {
      if (j_launch.rows.length > 0) {
        launch_ids.splice(k, 1);
        del_wrong_launchs(res, type_ids, exp_ids, launch_ids, user, k);
      } else {
        del_wrong_launchs(res, type_ids, exp_ids, launch_ids, user, k + 1);
      }
    });
  } else {
    res.render('main.ejs', {type_ids: type_ids, exp_ids: exp_ids, launch_ids: launch_ids});
    main(user);
  }
}

function main(user) {

  app.post("/download", urlencodedParser, function (req, res) {
    var launch_id = req.body.launch_id;
    app.use(express.static('./gits'));
    pool.query(`SELECT exp_id FROM launch WHERE id = $1;`, [launch_id], (err, exp_id) => {
      exp_id = exp_id.rows[0].exp_id;
        pool.query(`SELECT type_exp_id FROM exp WHERE id = $1;`, [exp_id], (err, type_id) => {
          type_id = type_id.rows[0].type_exp_id;
          async function foo(launch_id, exp_id, type_id, user) {
            await sysgit.run_script_rdLAU(["./gits", `${user}`, `TE${type_id}`, `EXP${exp_id}`, `LAU${launch_id}`], 'done');
            res.render('download.ejs', {file_href: `/${user}/Algo500.data/TE${type_id}_EXP${exp_id}_LAU${launch_id}.zip`});
          }
          foo(launch_id, exp_id, type_id, user);
        });
    });
  })

app.post("/new_type", urlencodedParser, function (req, res) {
  var n_pth = req.body.n_pth;
  var n_ccond = req.body.n_ccond;
  var n_vcond = req.body.n_vcond;
  var n_result = req.body.n_result;
  res.render('type_new.ejs', {n_pth: n_pth, n_ccond: n_ccond, n_vcond: n_vcond, n_result: n_result});
  app.post("/new_type/posted", urlencodedParser, function (req, res) {
    if(!req.body) return res.sendStatus(400);
    const name = `"` + req.body.name + `"`;
    const goal = `"` + req.body.goal + `"`;
    var pth_str = ``;
    var ccond = ``;
    var vcond = ``;
    var result = ``;
    var query_str = `SELECT type_exp_new(CAST ('{"name", "goal"`;
    if (n_pth > 0) {
      query_str += `, "path_to_type"`;
      pth_str += `{"ref": "` + req.body[`pth_ref0`] + `", "name": "` + req.body[`pth_name0`] + `", "type": "` + req.body[`pth_type0`] + `"}`;
      for (var i = 1; i < n_pth; i++) {
        pth_str += `, {"ref": "` + req.body[`pth_ref${i}`] + `", "name": "` + req.body[`pth_name${i}`] + `", "type": "` + req.body[`pth_type${i}`] + `"}`;
      }
    }
    if (n_ccond > 0) {
      query_str += `, "ccond"`
      ccond += `"` + req.body[`ccond0`] + `", "` + req.body[`ccond_unit0`] + `"`;
      for (var i = 1; i < n_ccond; i++) {
        ccond += `, "` + req.body[`ccond${i}`] + `", "` + req.body[`ccond_unit${i}`] + `"`;
      }
    }
    if (n_vcond > 0) {
      query_str += `, "vcond"`
      vcond += `"` + req.body[`vcond0`] + `", "` + req.body[`vcond_unit0`] + `"`;
      for (var i = 1; i < n_vcond; i++) {
        vcond += `, "` + req.body[`vcond${i}`] + `", "` + req.body[`vcond_unit${i}`] + `"`;
      }
    }
    if (n_result > 0) {
      query_str += `, "result"`
      result += `"` + req.body[`result0`] + `", "` + req.body[`result_unit0`] + `"`;
      for (var i = 1; i < n_result; i++) {
        result += `, "` + req.body[`result${i}`] + `", "` + req.body[`result_unit${i}`] + `"`;
      }
    }
    query_str += `}' AS name[]), CAST ('[`;
    query_str += name + `, ` + goal;
    if (n_pth > 0) {
      query_str += `, [` + pth_str + `]`;
    }
    if (n_ccond > 0) {
      query_str += `, [` + ccond + `]`;
    }
    if (n_vcond > 0) {
      query_str += `, [` + vcond + `]`;
    }
    if (n_result > 0) {
      query_str += `, [` + result + `]`;
    }
    query_str += `]' AS jsonb), ${user});`;
    console.log(query_str);
    pool.query(query_str, (err, type_id) => {
      if(err) return console.log(err);
      var files = req.files;
      type_id = type_id.rows[0].type_exp_new;
      async function foo(files, type_id, user) {
        await sysgit.run_script_crtTE(["./gits", `${user}`, `TE${type_id}`], 'done');
        var dir = `./gits/${user}/TE${type_id}/common/`;
        if (files != undefined) {
          files = files.gits;
          if (files.length != undefined) {
            for (var j = 0; j < files.length; j++) {
              files[j].mv(dir + files[j].name);
            }
          } else {
            files.mv(dir + files.name);
          }
        }
        await sysgit.run_script_brTE(["./gits", `${user}`, `TE${type_id}`], 'done');
      }
      foo(files, type_id, user);
    });
  });
  
});

app.post("/upd_type", urlencodedParser, function (req, res) {
  var type_id = req.body.type_id;
  var ch_name = req.body.ch_name;
  var ch_goal = req.body.ch_goal;
  var ch_pth = req.body.ch_pth;
  var ch_ccond = req.body.ch_ccond;
  var ch_vcond = req.body.ch_vcond;
  var ch_result = req.body.ch_result;
  var n_pth = req.body.n_pth;
  pool.query(`SELECT ccond, vcond, result FROM type_exp WHERE id = ${type_id};`, (err, conds) => {
    var ccond = conds.rows[0].ccond;
    var vcond = conds.rows[0].vcond;
    var result = conds.rows[0].result;
    var n_ccond, n_vcond, n_result;
    if (ccond) {
      n_ccond = ccond.length / 2;
    } else {
      n_ccond = 0;
    }
    if (vcond) {
      n_vcond = vcond.length / 2;
    } else {
      n_vcond = 0;
    }
    if (result) {
      n_result = result.length / 2;
    } else {
      n_result = 0;
    }
    res.render('type_upd.ejs', {type_id: type_id, ch_name: ch_name, ch_goal: ch_goal, ch_pth: ch_pth, ch_ccond: ch_ccond, ch_vcond: ch_vcond, ch_result: ch_result, n_pth: n_pth, n_ccond: n_ccond, n_vcond: n_vcond, n_result: n_result, ccond: ccond, vcond: vcond, result: result});
    app.post("/upd_type/posted", urlencodedParser, function (req, res) {
      if(!req.body) return res.sendStatus(400);
      var pth_str = ``;
      var ccond = ``;
      var vcond = ``;
      var result = ``;
      var query_str = `SELECT type_exp_upd(` + type_id + `, CAST ('{`;
      if (ch_name == 1) {
        query_str += `"name", `;
      }
      if (ch_goal == 1) {
        query_str += `"goal", `;
      }
      if (ch_pth == 1) {
        query_str += `"path_to_type", `;
        pth_str += `{"ref": "` + req.body[`pth_ref0`] + `", "name": "` + req.body[`pth_name0`] + `", "type": "` + req.body[`pth_type0`] + `"}`;
        for (var i = 1; i < n_pth; i++) {
          pth_str += `, {"ref": "` + req.body[`pth_ref${i}`] + `", "name": "` + req.body[`pth_name${i}`] + `", "type": "` + req.body[`pth_type${i}`] + `"}`;
        }
      }
      if (ch_ccond == 1 && n_ccond > 0) {
        query_str += `"ccond", `
        ccond += `"` + req.body[`ccond0`] + `", "` + req.body[`ccond_unit0`] + `"`;
        for (var i = 1; i < n_ccond; i++) {
          ccond += `, "` + req.body[`ccond${i}`] + `", "` + req.body[`ccond_unit${i}`] + `"`;
        }
      }
      if (ch_vcond == 1 && n_vcond > 0) {
        query_str += `"vcond", `
        vcond += `"` + req.body[`vcond0`] + `", "` + req.body[`vcond_unit0`] + `"`;
        for (var i = 1; i < n_vcond; i++) {
          vcond += `, "` + req.body[`vcond${i}`] + `", "` + req.body[`vcond_unit${i}`] + `"`;
        }
      }
      if (ch_result == 1 && n_result > 0) {
        query_str += `"result", `
        result += `"` + req.body[`result0`] + `", "` + req.body[`result0`] + `"`;
        for (var i = 1; i < n_result; i++) {
          result += `, "` + req.body[`result${i}`] + `", "` + req.body[`result${i}`] + `"`;
        }
      }
      query_str = query_str.slice(0, -2);
      query_str += `}' AS name[]), CAST ('[`;
      if (ch_name == 1) {
        query_str += `"` + req.body.name + `", `;
      }
      if (ch_goal == 1) {
        query_str += `"` + req.body.goal + `", `;
      }
      if (ch_pth == 1) {
        query_str += `[` + pth_str + `], `;
      }
      if (ch_ccond == 1 && n_ccond > 0) {
        query_str += `[` + ccond + `], `;
      }
      if (ch_vcond == 1 && n_vcond > 0) {
        query_str += `[` + vcond + `], `;
      }
      if (ch_result == 1 && n_result > 0) {
        query_str += `[` + result + `], `;
      }
      query_str = query_str.slice(0, -2);
      query_str += `]' AS jsonb), ${user});`;
      console.log(query_str);
      pool.query(query_str, (err, launch) => {
        if(err) return console.log(err);
      });
    });
  });
});

app.post("/del_type", urlencodedParser, function (req, res) {
  var type_id = req.body.type_id;
  var query_str = `SELECT type_exp_del(${type_id}, ${user});`;
  console.log(query_str);
  pool.query(query_str, (err, launch) => {
    if(err) return console.log(err);
  });
});

app.post("/new_exp", urlencodedParser, function (req, res) {
  var type_id = req.body.type_id;
  var n_pth = req.body.n_pth;
  pool.query(`SELECT ccond FROM type_exp WHERE id = $1;`, [type_id], (err, conds) => {
    var ccond = conds.rows[0].ccond;
    pool.query(`SELECT * from scomp;`, (err, scomps) => {
      scomps = scomps.rows;
      pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND user = $2 AND operation = 1 AND state = 0;`, [type_id, user], (err, upds) => {
        if (upds) {
          upds = upds.rows;
          var i = upds.findLastIndex(item => item.col_set.includes('ccond'));
          if (i != -1) {
            upds = upds[i];
            upds.col_set = upds.col_set.split(',');
            upds.col_set[0] = upds.col_set[0].slice(1);
            upds.col_set[upds.col_set.length-1] = upds.col_set[upds.col_set.length-1].slice(0, -1);
            ccond = upds.new_val_set[upds.col_set.findIndex(item => item == 'ccond')];
          }
        }
        if (ccond) {
          var n_ccond = ccond.length / 2;
        } else {
          var n_ccond = 0;
        }
        res.render('exp_new.ejs', {n_pth: n_pth, ccond: ccond, scomps: scomps});
        app.post("/new_exp/posted", urlencodedParser, function (req, res) {
          if(!req.body) return res.sendStatus(400);
          const name = `"` + req.body.name + `"`;
          const goal = `"` + req.body.goal + `"`;
          const sc_id = `${req.body.sc_id}`;
          var pth_str = ``;
          var ccond = ``;
          var query_str = `SELECT exp_new(CAST ('{"type_exp_id", "exp_name", "exp_goal", "sc_id"`;
          if (n_pth > 0) {
            query_str += `, "path_to_exp"`;
            pth_str += `{"ref": "` + req.body[`pth_ref0`] + `", "name": "` + req.body[`pth_name0`] + `", "type": "` + req.body[`pth_type0`] + `"}`;
            for (var i = 1; i < n_pth; i++) {
              pth_str += `, {"ref": "` + req.body[`pth_ref${i}`] + `", "name": "` + req.body[`pth_name${i}`] + `", "type": "` + req.body[`pth_type${i}`] + `"}`;
            }
          }
          if (n_ccond > 0) {
            query_str += `, "ccond"`
            ccond += `"` + req.body[`ccond0`] + `"`;
            for (var i = 1; i < n_ccond; i++) {
              ccond += `, "` + req.body[`ccond${i*2}`] + `"`;
            }
          }
          query_str += `}' AS name[]), CAST ('[`;
          query_str += `${type_id}, ` + name + `, ` + goal + `, ` + sc_id;
          if (n_pth > 0) {
            query_str += `, [` + pth_str + `]`;
          }
          if (n_ccond > 0) {
            query_str += `, [` + ccond + `]`;
          }
          query_str += `]' AS jsonb), ${user});`;
          console.log(query_str);
          pool.query(query_str, (err, exp_id) => {
            if(err) return console.log(err);
            exp_id = exp_id.rows[0].exp_new;
            var files = req.files;
            async function foo(files, exp_id, type_id, user) {
              await sysgit.run_script_crtEXP(["./gits", `${user}`, `TE${type_id}`, `EXP${exp_id}`], 'done');
              var dir = `./gits/${user}/Algo500.data/TE${type_id}/EXP${exp_id}/`;
              if (files != undefined) {
                files = files.gits;
                if (files.length != undefined) {
                  for (var j = 0; j < files.length; j++) {
                    files[j].mv(dir + files[j].name);
                  }
                } else {
                  files.mv(dir + files.name);
                }
              }
              await sysgit.run_script_brEXP(["./gits", `${user}`, `TE${type_id}`, `EXP${exp_id}`], 'done');
            }
            foo(files, exp_id, type_id, user);
          });
        });
      });
    });
  });
});

app.post("/upd_exp", urlencodedParser, function (req, res) {
  var exp_id = req.body.exp_id;
  var ch_name = req.body.ch_name;
  var ch_goal = req.body.ch_goal;
  var ch_sc = req.body.ch_sc;
  var ch_pth = req.body.ch_pth;
  var ch_ccond = req.body.ch_ccond;
  var n_pth = req.body.n_pth;
  pool.query(`SELECT type_exp_id FROM exp WHERE id = $1;`, [exp_id], (err, type) => {
    var type_id = type.rows[0].type_exp_id;
      pool.query(`SELECT ccond FROM type_exp WHERE id = $1;`, [type_id], (err, conds) => {
      var ccond = conds.rows[0].ccond;
      pool.query(`SELECT * from scomp;`, (err, scomps) => {
        scomps = scomps.rows;
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND user = $2 AND operation = 1 AND state = 0;`, [type_id, user], (err, upds) => {
          if (upds) {
            upds = upds.rows;
            var i = upds.findLastIndex(item => item.col_set.includes('ccond'));
            if (i != -1) {
              upds = upds[i];
              upds.col_set = upds.col_set.split(',');
              upds.col_set[0] = upds.col_set[0].slice(1);
              upds.col_set[upds.col_set.length-1] = upds.col_set[upds.col_set.length-1].slice(0, -1);
              ccond = upds.new_val_set[upds.col_set.findIndex(item => item == 'ccond')];
            }
          }
          if (ccond) {
            var n_ccond = ccond.length / 2;
          } else {
            var n_ccond = 0;
          }
          res.render('exp_upd.ejs', {ch_name: ch_name, ch_goal: ch_goal, ch_sc: ch_sc, ch_pth: ch_pth, ch_ccond: ch_ccond, n_pth: n_pth, ccond: ccond, scomps: scomps});
          app.post("/upd_exp/posted", urlencodedParser, function (req, res) {
            if(!req.body) return res.sendStatus(400);
            var pth_str = ``;
            var ccond = ``;
            var query_str = `SELECT exp_upd(` + exp_id + `, CAST ('{`;
            if (ch_name == 1) {
              query_str += `"exp_name", `;
            }
            if (ch_goal == 1) {
              query_str += `"exp_goal", `;
            }
            if (ch_sc == 1) {
              query_str += `"sc_id", `;
            }
            if (ch_pth == 1 && n_pth > 0) {
              query_str += `"path_to_exp", `;
              pth_str += `{"ref": "` + req.body[`pth_ref0`] + `", "name": "` + req.body[`pth_name0`] + `", "type": "` + req.body[`pth_type0`] + `"}`;
              for (var i = 1; i < n_pth; i++) {
                pth_str += `, {"ref": "` + req.body[`pth_ref${i}`] + `", "name": "` + req.body[`pth_name${i}`] + `", "type": "` + req.body[`pth_type${i}`] + `"}`;
              }
            }
            if (ch_ccond == 1 && n_ccond > 0) {
              query_str += `"ccond", `
              ccond += `"` + req.body[`ccond0`] + `"`;
              for (var i = 1; i < n_ccond; i++) {
                ccond += `, "` + req.body[`ccond${i * 2}`] + `"`;
              }
            }
            query_str = query_str.slice(0, -2);
            query_str += `}' AS name[]), CAST ('[`;
            if (ch_name == 1) {
              query_str += `"` + req.body.name + `", `;
            }
            if (ch_goal == 1) {
              query_str += `"` + req.body.goal + `", `;
            }
            if (ch_sc == 1) {
              query_str += `${req.body.sc_id}, `;
            }
            if (ch_pth == 1) {
              query_str += `[` + pth_str + `], `;
            }
            if (ch_ccond == 1 && n_ccond > 0) {
              query_str += `[` + ccond + `], `;
            }
            query_str = query_str.slice(0, -2);
            query_str += `]' AS jsonb), ${user});`;
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
  var exp_id = req.body.exp_id;
  var query_str = `SELECT exp_del(${exp_id}, ${user});`;
  console.log(query_str);
  pool.query(query_str, (err, launch) => {
    if(err) return console.log(err);
  });
});

app.post("/new_launch", urlencodedParser, function (req, res) {
  var exp_id = req.body.exp_id;
  pool.query(`SELECT type_exp_id FROM exp WHERE id = $1;`, [exp_id], (err, type_id) => {
    type_id = type_id.rows[0].type_exp_id;
    pool.query(`SELECT vcond, result FROM type_exp WHERE id = $1;`, [type_id], (err, conds) => {
      var vcond = conds.rows[0].vcond;
      var result = conds.rows[0].result;
      pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND user = $2 AND operation = 1 AND state = 0;`, [type_id, user], (err, upds) => {
        if (upds) {
          upds = upds.rows;
          var i = upds.findLastIndex(item => item.col_set.includes('vcond'));
          if (i != -1) {
            var type_vcond = upds[i];
            type_vcond.col_set = type_vcond.col_set.split(',');
            type_vcond.col_set[0] = type_vcond.col_set[0].slice(1);
            type_vcond.col_set[type_vcond.col_set.length-1] = type_vcond.col_set[type_vcond.col_set.length-1].slice(0, -1);
            vcond = type_vcond.new_val_set[type_vcond.col_set.findIndex(item => item == 'vcond')];
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
            result = upds.new_val_set[upds.col_set.findIndex(item => item == 'result')];
          }
        }
        var n_vcond, n_result;
        if (vcond) {
          n_vcond = vcond.length / 2;
        } else {
          n_vcond = 0;
        }
        if (result) {
          n_result = result.length / 2;
        } else {
          n_result = 0;
        }
        res.render('launch_new.ejs', {vcond: vcond, result: result});
        app.post("/new_launch/posted", urlencodedParser, function (req, res) {
          if(!req.body) return res.sendStatus(400);
          var vcond = ``;
          var result = ``;
          var query_str = `SELECT launch_new(CAST ('{"exp_id", `;
          if (n_vcond > 0) {
            query_str += `"vcond", `
            vcond += `"` + req.body[`vcond0`] + `"`;
            for (var i = 1; i < n_vcond; i++) {
              vcond += `, "` + req.body[`vcond${i * 2}`] + `"`;
            }
          }
          query_str += `"result"`
          result += `"` + req.body[`result0`] + `"`;
          for (var i = 1; i < n_result; i++) {
            result += `, "` + req.body[`result${i* 2}`] + `"`;
          }
          query_str += `}' AS name[]), CAST ('[${exp_id}`;
          if (n_vcond > 0) {
            query_str += `, [` + vcond + `]`;
          }
          query_str += `, [` + result + `]`;
          query_str += `]' AS jsonb), ${user});`;
          console.log(query_str);
          pool.query(query_str, (err, launch_id) => {
            if(err) return console.log(err);
            var files = req.files;
            launch_id = launch_id.rows[0].launch_new;
            async function foo(files, launch_id, exp_id, type_id, user) {
              await sysgit.run_script_crtLAU(["./gits", `${user}`, `TE${type_id}`, `EXP${exp_id}`, `LAU${launch_id}`], 'done');
              var dir = `./gits/${user}/Algo500.data/TE${type_id}/EXP${exp_id}/LAU${launch_id}/`;
              if (files != undefined) {
                files = files.gits;
                if (files.length != undefined) {
                  for (var j = 0; j < files.length; j++) {
                    files[j].mv(dir + files[j].name);
                  }
                } else {
                  files.mv(dir + files.name);
                }
              }
              await sysgit.run_script_brLAU(["./gits", `${user}`, `TE${type_id}`, `EXP${exp_id}`, `LAU${launch_id}`], 'done');
            }
            foo(files, launch_id, exp_id, type_id, user);
          });
        });
      });
    });
  });
});

app.post("/upd_launch", urlencodedParser, function (req, res) {
  var launch_id = req.body.launch_id;
  var ch_vcond = req.body.ch_vcond;
  var ch_result = req.body.ch_result;
  pool.query(`SELECT exp_id FROM launch WHERE id = $1;`, [launch_id], (err, exp_id) => {
    exp_id = exp_id.rows[0].exp_id;
    pool.query(`SELECT type_exp_id FROM exp WHERE id = $1;`, [exp_id], (err, type_exp_id) => {
      var type_id = type_exp_id.rows[0].type_exp_id;
      pool.query(`SELECT vcond, result FROM type_exp WHERE id = $1;`, [type_id], (err, conds) => {
        var vcond = conds.rows[0].vcond;
        var result = conds.rows[0].result;
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND "user" = $2 AND operation = 1 AND state = 0;`, [type_id, user], (err, upds) => {
          if (upds) {
            upds = upds.rows;
            var i = upds.findLastIndex(item => item.col_set.includes('vcond'));
            if (i != -1) {
              var type_vcond = upds[i];
              type_vcond.col_set = type_vcond.col_set.split(',');
              type_vcond.col_set[0] = type_vcond.col_set[0].slice(1);
              type_vcond.col_set[type_vcond.col_set.length-1] = type_vcond.col_set[type_vcond.col_set.length-1].slice(0, -1);
              vcond = type_vcond.new_val_set[type_vcond.col_set.findIndex(item => item == 'vcond')];
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
              result = upds.new_val_set[upds.col_set.findIndex(item => item == 'result')];
            }
          }
          var n_vcond, n_result;
          if (vcond) {
            n_vcond = vcond.length / 2;
          } else {
            n_vcond = 0;
          }
          if (result) {
            n_result = result.length / 2;
          } else {
            n_result = 0;
          }
          res.render('launch_upd.ejs', {vcond: vcond, result: result, ch_vcond: ch_vcond, ch_result: ch_result});
          app.post("/upd_launch/posted", urlencodedParser, function (req, res) {
            if(!req.body) return res.sendStatus(400);
            var vcond = ``;
            var result = ``;
            var query_str = `SELECT launch_upd(${launch_id}, CAST ('{`;
            if (ch_vcond == 1 && n_vcond > 0) {
              query_str += `"vcond"`
              vcond += `"` + req.body[`vcond0`] + `"`;
              for (var i = 1; i < n_vcond; i++) {
                vcond += `, "` + req.body[`vcond${i * 2}`] + `"`;
              }
            }
            if (ch_result == 1 && n_result > 0) {
              if (ch_vcond == 1 && n_vcond > 0) {
                query_str += `, "result"`;
              } else {
                query_str += `"result"`;
              }
              result += `"` + req.body[`result0`] + `"`;
              for (var i = 1; i < n_result; i++) {
                result += `, "` + req.body[`result${i * 2}`] + `"`;
              }
            }
            query_str += `}' AS name[]), CAST ('[`;
            if (ch_vcond == 1 && n_vcond > 0) {
              query_str += `[` + vcond + `]`;
            }
            if (ch_result == 1 && n_result > 0) {
              if (ch_vcond == 1) {
                query_str += `, [` + result + `]`;
              } else {
                query_str += `[` + result + `]`;
              }
            }
            query_str += `]' AS jsonb), ${user});`;
            console.log(query_str);
            pool.query(query_str, (err, no) => {
              if(err) return console.log(err);
              var files = req.files;
              launch_id = launch_id.rows[0].launch_new;
              async function foo(files, launch_id, exp_id, type_id, user) {
                await sysgit.run_script_crtLAU(["./gits", `${user}`, `TE${type_id}`, `EXP${exp_id}`, `LAU${launch_id}`], 'done');
                var dir = `./gits/${user}/Algo500.data/TE${type_id}/EXP${exp_id}/LAU${launch_id}/`;
                if (files != undefined) {
                  files = files.gits;
                  if (files.length != undefined) {
                    for (var j = 0; j < files.length; j++) {
                      files[j].mv(dir + files[j].name);
                    }
                  } else {
                    files.mv(dir + files.name);
                  }
                }
                await sysgit.run_script_brLAU(["./gits", `${user}`, `TE${type_id}`, `EXP${exp_id}`, `LAU${launch_id}`], 'done');
              }
              foo(files, launch_id, exp_id, type_id, user);
            });
          });
        });
      });
    });
  });
});

app.post("/del_launch", urlencodedParser, function (req, res) {
  var launch_id = req.body.launch_id;
  var query_str = `SELECT launch_del(${launch_id}, ${user});`;
  console.log(query_str);
  pool.query(query_str, (err, launch) => {
    if(err) return console.log(err);
  });
});

app.post("/type_ids", urlencodedParser, function (req, res) {
  pool.query(`SELECT * from type_exp;`, (err, types) => {
    types = types.rows;
    types.sort(function(a, b){
      return a.id - b.id;
    });
    pool.query(`SELECT user;`, [], (err, user) => {
      user = user.rows[0].current_user;
      checkType(res, pool, types, user, 0);
    });
  });
});

function checkType(res, pool, types, user, k) {
  if (k < types.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [types[k].id, user], (err, j_type) => {
      if (j_type.rows.length > 0) {
        types.splice(k, 1);
        checkType(res, pool, types, user, k);
      } else {
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND "user" = $2 AND operation = 1 AND state = 0;`, [types[k].id, user], (err, j_type) => {
          j_type = j_type.rows;
          for(var i = 0; i < j_type.length; i++) {
            j_type[i].col_set = j_type[i].col_set.split(',');
            j_type[i].col_set[0] = j_type[i].col_set[0].slice(1);
            j_type[i].col_set[j_type[i].col_set.length-1] = j_type[i].col_set[j_type[i].col_set.length-1].slice(0, -1);
            for (var j = 0; j < j_type[i].col_set.length; j++) {
              types[k][j_type[i].col_set[j]] = j_type[i].new_val_set[j];
            }
          }
          k++;
          checkType(res, pool, types, user, k);
        });
      }
    });
  } else {
    res.render('type_ids.ejs', {types: types});
  }
}

app.post("/look", urlencodedParser, function (req, res) {
  var type_id = req.body.type_id;
  var show_id = req.body.show_id;
    pool.query(`SELECT * from type_exp WHERE id = $1;`, [type_id], (err, type) => {
      pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
      [type_id, user], (err, j_type) => {
        if (err) console.log(err);
        if (j_type.rows != undefined && j_type.rows.length > 0) {
          type = [];
        } else {
          type = type.rows[0];
        }
        if (type.length == 0) {
          res.render('empty.ejs', {});
        }
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'type_exp' AND "user" = $2 AND operation = 1 AND state = 0;`, [type_id, user], (err, j_type) => {
          j_type = j_type.rows;
          j_type.sort(function(a, b){
            return a.id - b.id;
          });
          for (var i = 0; i < j_type.length; i++) {
            j_type[i].col_set = j_type[i].col_set.split(',');
            j_type[i].col_set[0] = j_type[i].col_set[0].slice(1);
            j_type[i].col_set[j_type[i].col_set.length-1] = j_type[i].col_set[j_type[i].col_set.length-1].slice(0, -1);
            for (var j = 0; j < j_type[i].col_set.length; j++) {
              type[j_type[i].col_set[j]] = j_type[i].new_val_set[j];
            }
          }
          pool.query(`SELECT * from exp WHERE type_exp_id = $1;`, [type_id], (err, exp) => {
            exp = exp.rows;
            exp.sort(function(a, b){
              return a.id - b.id;
            });
            checkExp(res, pool, type_id, show_id, type, exp, user, 0);
          });
        });
      });
    });
});

function checkExp(res, pool, type_id, show_id, type, exp, user, k) {
  if (k < exp.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'exp' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [exp[k].id, user], (err, j_exp) => {
      if (j_exp.rows != undefined && j_exp.rows.length > 0) {
        exp.splice(k, 1);
        checkExp(res, pool, type, exp, user, k);
      } else {
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'exp' AND "user" = $2 AND operation = 1 AND state = 0;`, [exp[k].id, user], (err, j_exp) => {
          j_exp = j_exp.rows;
          j_exp.sort(function(a, b){
            return a.id - b.id;
          });
          for (var i = 0; i < j_exp.length; i++) {
            j_exp[i].col_set = j_exp[i].col_set.split(',');
            j_exp[i].col_set[0] = j_exp[i].col_set[0].slice(1);
            j_exp[i].col_set[j_exp[i].col_set.length-1] = j_exp[i].col_set[j_exp[i].col_set.length-1].slice(0, -1);
            for (var j = 0; j < j_exp[i].col_set.length; j++) {
              exp[k][j_exp[i].col_set[j]] = j_exp[i].new_val_set[j];
            }
          }
          k++;
          checkExp(res, pool, type_id, show_id, type, exp, user, k);
        });
      }
    });
  } else {
    goThroughLaunches(res, pool, type_id, show_id, user, type, exp, [], [], 0);
  }
}

function goThroughLaunches(res, pool, type_id, show_id, user, type, exp, launches, exp_num, i) {
  if (i < exp.length) {
    pool.query(`SELECT * from launch WHERE exp_id = $1;`, [exp[i].id], (err, launch) => {
      launch = launch.rows;
      launch.sort(function(a, b){
        return a.id - b.id;
      });
      for (var j = 0; j < launch.length; j++) {
        launches.push(launch[j]);
        exp_num.push(i);
      }
      goThroughLaunches(res, pool, type_id, show_id, user, type, exp, launches, exp_num, i + 1);
    });
  } else {
    checkLaunch(res, pool, type_id, show_id, user, type, exp, launches, exp_num, 0);
  }
}

function checkLaunch(res, pool, type_id, show_id, user, type, exp, launches, exp_num, k) {
  if (k < launches.length) {
    pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'launch' AND (("user" = $2 AND operation = 2) OR ("user" != $2 AND operation = 0 AND state != 1));`,
    [launches[k].id, user], (err, j_launch) => {
        if (err) console.log(err);
        if (j_launch.rows != undefined && j_launch.rows.length > 0) {
        launches.splice(k, 1);
        checkLaunch(res, pool, show_id, user, type, exp, launches, exp_num, k);
      } else {
        pool.query(`SELECT * from journal WHERE foreign_id = $1 AND name_of_table = 'launch' AND "user" = $2 AND operation = 1 AND state = 0;`, [launches[k].id, user], (err, j_launch) => {
          j_launch = j_launch.rows;
          for (var i = 0; i < j_launch.length; i++) {
            j_launch[i].col_set = j_launch[i].col_set.split(',');
            j_launch[i].col_set[0] = j_launch[i].col_set[0].slice(1);
            j_launch[i].col_set[j_launch[i].col_set.length-1] = j_launch[i].col_set[j_launch[i].col_set.length-1].slice(0, -1);
            for (var j = 0; j < j_launch[i].col_set.length; j++) {
              launches[k][j_launch[i].col_set[j]] = j_launch[i].new_val_set[j];
            }
          }
          k++;
          checkLaunch(res, pool, type_id, show_id, user, type, exp, launches, exp_num, k);
        });
      }
    });
  } else {
    pool.query(`SELECT * FROM scomp;`, (err, scomps) => {
      scomps = scomps.rows;
      scomps.sort(function(a, b){
        return a.id - b.id;
      });
      res.render('table.ejs', {type_id: type_id, type: type, exp: exp, launch: launches, exp_num: exp_num, show_id: show_id, scomps: scomps});
    });
  }
}

}



app.listen(8000, 'web_server_ip', () =>{
    console.log('Server started');
});