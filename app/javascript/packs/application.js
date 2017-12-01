/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import { QSContainer } from './../components/qs/QSContainer';
import { MturkQSContainer } from './../components/qs/MturkQSContainer';
import { SentimentTextBox } from './../components/SentimentTextBox';
import WebpackerReact from 'webpacker-react'


// Register components using Webpacker-react 
Turbolinks.start()
WebpackerReact.setup({QSContainer, MturkQSContainer, SentimentTextBox})
