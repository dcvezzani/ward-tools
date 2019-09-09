var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var cors = require('cors');

var indexRouter = require('./routes/index');

const createError = (status, message) => {
  const err = Error("that resource doesn't seem to exist")
  err.status = 404
  return err
};

var app = express();

app.use(logger('dev'));
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());

app.use('/', indexRouter);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404, "that resource doesn't seem to exist"));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  console.log(">>>err", err.message)
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500).json({message: res.locals.message})
});

module.exports = app;
