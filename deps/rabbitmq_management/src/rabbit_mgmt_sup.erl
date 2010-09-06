%%   The contents of this file are subject to the Mozilla Public License
%%   Version 1.1 (the "License"); you may not use this file except in
%%   compliance with the License. You may obtain a copy of the License at
%%   http://www.mozilla.org/MPL/
%%
%%   Software distributed under the License is distributed on an "AS IS"
%%   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%   License for the specific language governing rights and limitations
%%   under the License.
%%
%%   The Original Code is RabbitMQ Management Console.
%%
%%   The Initial Developers of the Original Code are Rabbit Technologies Ltd.
%%
%%   Copyright (C) 2010 Rabbit Technologies Ltd.
%%
%%   All Rights Reserved.
%%
%%   Contributor(s): ______________________________________.
%%
-module(rabbit_mgmt_sup).

-behaviour(supervisor).

-export([init/1]).
-export([start_link/0]).

init([]) ->
    CmdLineCache = {rabbit_mgmt_cmdline_cache,
                    {rabbit_mgmt_cmdline_cache, start_link, []},
                    permanent, 5000, worker, [rabbit_mgmt_cmdline_cache]},
    DB = {rabbit_mgmt_db,
          {rabbit_mgmt_db, start_link, []},
          permanent, 5000, worker, [rabbit_mgmt_cmdline_cache]},
    {ok, {{one_for_one, 10, 10}, [CmdLineCache, DB]}}.

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).
