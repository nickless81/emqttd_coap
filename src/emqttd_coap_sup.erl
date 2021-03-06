%%--------------------------------------------------------------------
%% Copyright (c) 2016 Feng Lee <feng@emqtt.io>. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqttd_coap_sup).

-author("Feng Lee <feng@emqtt.io>").

-behaviour(supervisor).

-export([start_link/1, init/1]).

-define(CHILD(M), {M, {M, start_link, []}, permanent, 5000, worker, [M]}).

start_link(Listeners) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [Listeners]).

init([Listeners]) ->
    io:format("Listeners: ~p~n", [Listeners]),
    ChSup = {emqttd_coap_channel_sup,
             {emqttd_coap_channel_sup, start_link, []},
              permanent, infinity, supervisor, [emqttd_coap_channel_sup]},
    ChMFA = {emqttd_coap_channel_sup, start_channel, []},
    {ok, {{one_for_all, 10, 3600},
          [ChSup, ?CHILD(emqttd_coap_observer), ?CHILD(emqttd_coap_server) |
           [listener_child(Listener, ChMFA) || Listener <- Listeners]]}}.

listener_child({listener, Name, Port, Opts}, ChMFA) ->
    {{coap_listener, Name},
      {esockd_udp, server, [Name, Port, Opts, ChMFA]},
        permanent, 5000, worker, [esockd_udp]}.

