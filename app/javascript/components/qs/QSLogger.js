import moment from 'moment';

export class QSLogger {
  constructor(delayStart = 0, delayNextQuestion = 0) {
    this.timeLastAnswer = null;
    this.delayStart = delayStart;
    this.delayNextQuestion = delayNextQuestion;
    this.timeMounted = null;
    this.initializeLog();
  }

  getLog() {
    return this.log;
  }

  getTime() {
    return new Date().getTime();
  }

  reset() {
    this.initializeLog();
    this.logMounted();
  }

  logResult(questionId, time) {
    this.log['results'].push({
      'submitTime': time,
      'timeSinceLastAnswer': time - this.timeLastAnswer,
      'questionId': questionId,
    });
    this.timeLastAnswer = time;
  }

  logFinal(time) {
    this.log['totalDurationQuestionSequence'] = time - this.log['timeMounted'];
    this.log['timeQuestionSequenceEnd'] = time;
  }

  logMturkSubmit(time) {
    this.log['totalDurationUntilMturkSubmit'] = time - this.log['timeMounted'];
    this.log['timeMturkSubmit'] = time;
  }

  initializeLog() {
    this.log = {
      'timeInitialized': this.getTime(),
      'userTimeInitialized': moment().format(),
      'results': [],
      'resets': [],
      'delayStart': this.delayStart,
      'delayNextQuestion': this.delayNextQuestion,
      'timeMounted': this.timeMounted,
    }
  }

  logMounted() {
    const now = this.getTime()
    this.log['timeMounted'] = now;
    this.timeLastAnswer = now;
    this.timeMounted = now;
  }

  logReset(questionId) {
    this.log['resets'].push({
      'resetTime': this.getTime(),
      'resetAtQuestionId': questionId,
      'previousResultLog': this.log['results']
    });
    this.log['results'] = [];
  }
}
