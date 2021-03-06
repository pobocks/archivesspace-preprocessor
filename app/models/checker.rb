# Schematron-based XSLT checker that finds and reports errors in EAD files
class Checker
  def initialize(stron = ->() {Schematron.current}, run = nil)
    @schematron = stron.kind_of?(Proc) ? stron.call : stron
    @issue_ids = stron.issues.pluck(:identifier, :id).to_h
    @checker = Schematronium.new(@schematron.file)
    @run = run
  end

  # @param faid [FindingAid, FindingAidVersion] An input EAD to be checked via Schematron
  # @return [Array] Issues found, elements of array are suitable for passing to ConcreteIssues constructor
  def check(faid)
    # Resolve down to concrete FindingAidFile for passing to Schematronium
    faid = faid.current if faid.is_a? FindingAid

    s_xml = Saxon.XML(faid.file)
    xml = @checker.check(faid.file)
    xml.remove_namespaces!
    errs = xml.xpath('//failed-assert | //successful-report')


    errs.map do |el|
      diag = el.at_xpath('./diagnostic-reference')
      {
        run_id: @run.try(:id),
        finding_aid_version_id: faid.id,
        issue_id: @issue_ids[diag['diagnostic']],
        location: el['location'],
        line_number: s_xml.xpath(el['location']).get_line_number,
        diagnostic_info: diag.inner_html
      }
    end
  end

  # Note: Separate str version exists because saxon XML can't provide line numbers when run on a str not backed by a file
  # @param xmlstr [String] An input string containing EAD content to be checked via Schematron
  # @return [Array<Hash>] Issues found, elements of array are suitable for passing to ConcreteIssues constructor
  def check_str(xmlstr)
    xml = @checker.check(xmlstr)
    xml.remove_namespaces!
    errs = xml.xpath('//failed-assert | //successful-report')

    errs.map do |el|
      diag = el.at_xpath('./diagnostic-reference')
      {
        run_id: @run.try(:id),
        issue_id: @issue_ids[diag['diagnostic']],
        location: el['location'],
        line_number: -1,
        diagnostic_info: diag.inner_html
      }
    end
  end
end
