defmodule PayrollApiWeb.I18n do
  @moduledoc """
  Lightweight i18n for API response labels. Supports English (en, default)
  and Bahasa Malaysia (ms). Controlled via the `lang` request param.
  """

  @translations %{
    "en" => %{
      success: "success",
      wage: "wage",
      employee_contributions: "employee_contributions",
      employer_contributions: "employer_contributions",
      epf: "EPF",
      socso: "SOCSO",
      eis: "EIS",
      hrdf: "HRDF",
      pcb: "PCB (income tax)",
      total: "total",
      net_pay: "net_pay",
      total_statutory_cost: "total_employer_cost",
      tax_details: "tax_details",
      annual_gross: "annual_gross",
      annual_reliefs: "annual_reliefs",
      annual_chargeable: "annual_chargeable",
      annual_tax: "annual_tax",
      rates: "rates",
      minimum_wage: "minimum_wage",
      rates_version: "rates_version"
    },
    "ms" => %{
      success: "berjaya",
      wage: "gaji",
      employee_contributions: "caruman_pekerja",
      employer_contributions: "caruman_majikan",
      epf: "KWSP",
      socso: "PERKESO",
      eis: "SIP",
      hrdf: "PSMB",
      pcb: "PCB (cukai pendapatan)",
      total: "jumlah",
      net_pay: "gaji_bersih",
      total_statutory_cost: "jumlah_kos_majikan",
      tax_details: "butiran_cukai",
      annual_gross: "pendapatan_tahunan",
      annual_reliefs: "pelepasan_tahunan",
      annual_chargeable: "pendapatan_bercukai",
      annual_tax: "cukai_tahunan",
      rates: "kadar",
      minimum_wage: "gaji_minimum",
      rates_version: "versi_kadar"
    }
  }

  @doc "Resolve language code from request param (default en)."
  def lang(nil), do: "en"
  def lang("ms"), do: "ms"
  def lang("ms-MY"), do: "ms"
  def lang("bm"), do: "ms"
  def lang(_), do: "en"

  @doc "Translate a label key for the language."
  def t(lang, key) do
    get_in(@translations, [lang, key]) || get_in(@translations, ["en", key]) || Atom.to_string(key)
  end
end
