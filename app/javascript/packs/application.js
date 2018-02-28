/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import WebpackerReact from 'webpacker-react'
import { QSContainer } from './../components/qs/QSContainer';
import { MturkQSContainer } from './../components/qs/MturkQSContainer';
import { SentimentTextBox } from './../components/sent_textbox/SentimentTextBox';
import { SentimentVisualization } from './../components/sent_viz/SentimentVisualization';
import { MonitorStream } from './../components/monitor_stream/MonitorStream';
import { Leadline } from './../components/frontpage/Leadline';
import { UserActivity } from './../components/user_activity/UserActivity';

// Register components using Webpacker-react 
Turbolinks.start()
WebpackerReact.setup({QSContainer, MturkQSContainer, SentimentTextBox, SentimentVisualization, MonitorStream, Leadline, UserActivity})

// this is needed for components to properly unmount and not being cached
$(document).on('turbolinks:before-cache', () => WebpackerReact.unmountComponents())
