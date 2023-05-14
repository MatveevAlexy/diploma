/* Модуль создает экземпляр EventEmitter, который является общим для
 * всей программы. Через данный экземпляр происходит передача событий
 * внутри программы.
 */
'use strict';

const EventEmitter = new (require('events'));

module.exports =  EventEmitter;
