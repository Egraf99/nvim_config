local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local ch = ls.choice_node
local f = ls.function_node
local events = require("luasnip.util.events")

local function get_file_path()
    return vim.api.nvim_buf_get_name(0)
end

local function get_path_to_table()
    local path_to_domen = "intranet/hrdwh/etl/layers/"
    local _, _, layer, domain, report_name, table = string.find(get_file_path(), ".*" .. path_to_domen .. "(.-)/(.-)/(.*)/(.*)%.py$")
    return {layer=layer, domain=domain, report_name=report_name, table=table}
end

local function get_job_name()
    local path = get_path_to_table()
    local upper_table = string.upper(string.sub(path.table, 1, 1)) .. string.sub(path.table, 2)
    return string.gsub(upper_table, "%_(%a)", function (simbol) return string.upper(simbol) end) .. "Job"
end

local function get_table_name(args, _, _)
    return string.match(args[1][1], "/([^/]*)$")
end

return {

s("test",
    t([[//home/hrdwh/test/dwh/internal/]])
),

s("prod",
    t([[//home/hrdwh/prod/dwh/internal/]])
),

s("femida",
    t([[//home/femida/postgres/transfer/Stable/]])
),

s("spark",
    t({
        [[from hrdwh_utils.spark.session import get_local_spark_session]],
        [[spark = get_local_spark_session(discovery_path='//home/hrdwh/prod/spark/hrdwh_dev')]]

    })
),

s("read", {
    t([[spark.read.option("arrow_enabled", "false").yt("]]),
    ch(1, {
        i(1),
        sn(nil, {t([[//home/hrdwh/test/dwh/internal/]]), i(1)}),
        sn(nil, {t([[//home/hrdwh/prod/dwh/internal/]]), i(1)}),
        sn(nil, {t([[//home/femida/postgres/transfer/Stable/]]), i(1)}),
    }),
    t([[").createOrReplaceTempView("]]),
    f(get_table_name, {1}, {}),
    t([[")]])
}),

s("sql", sn(1, {
    ch(4, {
        t("spark"),
        t("job.chyt")
    }),
    t({
        ".sql(",
        [[    """]],
        "    select ",
        "        *",
        "    from "
    }),
    i(1),
    t({
        "",
        [[    """]],
        ").show(vertical="
    }),
    ch(2, {
        t("True"),
        t("False")
    }),
    t(", truncate="),
    ch(3, {
        t("200"),
        t("False"),
        i(1, "int")
    }),
    t(")")
})),


s(").show", sn(1, {
    t(").show(vertical="),
    ch(1, {
        t("True"),
        t("False")
    }),
    t(",truncate="),
    ch(2, {
        t("200"),
        t("False"),
        i(1, "int")
    }),
    t(")")
})),


s("init", {
    t({
[[from hrdwh_utils.jobs import DevHRDWHJob]],
[[from hrdwh_utils.endpoints.sources import Sources, HRDWHSource]],
[[from hrdwh_utils.endpoints.targets import Targets, HRDWHTarget]],
[[]],
[[from hrdwh_utils.utils import create_dependency_factory, LogosParams]],
[[]],
[[]],
[[class ]]}),
f(function() return get_job_name() end, {}, {}),
t({
[[(DevHRDWHJob):]],
[[    script_version = 0]],
[[    layer = "]]}),
f(function() return get_path_to_table().layer end, {}, {}),
t({
[["]],
[[    domain = "]]}),
f(function() return get_path_to_table().domain end, {}, {}),
t({[["]],
[[    report_name = "]]}),
f(function() return get_path_to_table().report_name end, {}, {}),
t({[["]],
[[]],
[[    sources = Sources([]],
[[        logos_params=LogosParams(timedelta="1d"),]],
[[        logos_deps=create_dependency_factory("current_trigger"),]],
[[    ])]],
[[]],
[[    targets = Targets(]],
[[        result=HRDWHTarget(]],
[[            "]]}),
f(function() return get_path_to_table().table end, {}, {}),
t({
[[",]],
[[            logos_params=LogosParams(timedelta="1d"))]],
[[    )]],
[[]],
[[    def do_run(self):]],
[[        result_df = self.spark.sql(]],
[[            """]],
[[            ]]}), i(1),
t({
[[]],
[[            """]],
[[        )]],
[[        self.set_dataframes(result=result_df)]],
[[]],
[[]],
[[def run_calc(spark, args, solomon_client, yt_client, inputs_and_outputs=None):]],
[[    job = ]]}),
f(function() return get_job_name() end, {}, {}),
t({
[[(spark, args, solomon_client, yt_client, inputs_and_outputs)]],
[[    job.run()]],
[[]],
[[]],
[[from hrdwh_utils.spark.session import get_local_spark_session]],
[[spark = get_local_spark_session(discovery_path='//home/hrdwh/prod/spark/hrdwh_dev', spark_cores_max=20)]],
[[]],
[[]],
[[job = ]]}),
f(function() return get_job_name() end, {}, {}),
t({
[[(spark)]],
[[job.init_sources_and_targets()]],
[[job.run()]],
})
}),

}
