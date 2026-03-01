import UIKit

final class PDFReportService {
  static let shared = PDFReportService()

  private let W: CGFloat = 612
  private let H: CGFloat = 792
  private let M: CGFloat = 48
  private var CW: CGFloat { W - M * 2 }

  private let navy  = UIColor(hex: "#2D4A6B")
  private let teal  = UIColor(hex: "#3AAA8C")
  private let amber = UIColor(hex: "#D4882A")

  // MARK: - Public

  func generate(
    episodes: [TriggerEpisode],
    tracker: ProgressTracker,
    journal: [JournalEntry],
    isPremium: Bool
  ) -> URL? {
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H))
    let data = renderer.pdfData { ctx in
      if isPremium {
        drawPremiumReport(ctx, episodes: episodes, tracker: tracker, journal: journal)
      } else {
        drawFreeReport(ctx, episodes: episodes, tracker: tracker)
      }
    }
    let name = isPremium ? "RelaxingCalm_FullReport.pdf" : "RelaxingCalm_Report.pdf"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
    try? data.write(to: url)
    return url
  }

  // MARK: - Free Report (1 page)

  private func drawFreeReport(
    _ ctx: UIGraphicsPDFRendererContext,
    episodes: [TriggerEpisode],
    tracker: ProgressTracker
  ) {
    ctx.beginPage()

    // Header band
    fill(CGRect(x: 0, y: 0, width: W, height: 76), color: navy)
    drawText("Relaxing Calm", in: CGRect(x: M, y: 16, width: CW * 0.6, height: 28),
             font: .boldSystemFont(ofSize: 22), color: .white)
    drawText("Anxiety & Panic Report", in: CGRect(x: M, y: 46, width: CW * 0.6, height: 18),
             font: .systemFont(ofSize: 13), color: .white.withAlphaComponent(0.75))
    let dateStr = "Generated: " + DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
    drawText(dateStr, in: CGRect(x: M, y: 32, width: CW, height: 18),
             font: .systemFont(ofSize: 10), color: .white.withAlphaComponent(0.65), align: .right)

    var y: CGFloat = 100

    // Summary stats
    sectionTitle("SUMMARY", y: &y)
    let week = episodes.filter {
      Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
    }.count
    let pct = episodes.isEmpty ? 0 : Int(Double(episodes.filter(\.isSuccess).count) / Double(episodes.count) * 100)
    kvLine("Total episodes logged", value: "\(episodes.count)", y: &y)
    kvLine("Episodes this week", value: "\(week)", y: &y)
    kvLine("Felt better after session", value: "\(pct)%", y: &y)
    kvLine("Current streak", value: "\(tracker.currentStreak) days", y: &y)
    kvLine("Longest streak", value: "\(tracker.longestStreak) days", y: &y)
    y += 20

    // Top triggers
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    let counts = Dictionary(grouping: episodes.filter { $0.timestamp >= cutoff }, by: \.triggerKey).mapValues { $0.count }
    let top = counts.sorted { $0.value > $1.value }.prefix(3)
    if !top.isEmpty {
      sectionTitle("TOP TRIGGERS  (last 30 days)", y: &y)
      for (key, cnt) in top {
        if let cat = TriggerEpisode.categories.first(where: { $0.key == key }) {
          bullet("\(cat.emoji)  \(cat.label) — \(cnt) episode\(cnt == 1 ? "" : "s")", y: &y)
        }
      }
      y += 20
    }

    // Recent episodes
    if !episodes.isEmpty {
      sectionTitle("RECENT EPISODES", y: &y)
      for ep in episodes.sorted(by: { $0.timestamp > $1.timestamp }).prefix(5) {
        bullet("\(ep.formattedTime)  ·  \(ep.triggerLabel)  ·  \(ep.isSuccess ? "Felt better ✓" : "Needed more help")", y: &y)
      }
      y += 20
    }

    // Upgrade CTA box
    fill(CGRect(x: M, y: H - 112, width: CW, height: 64), color: UIColor(white: 0.96, alpha: 1), radius: 10)
    fill(CGRect(x: M, y: H - 112, width: 4, height: 64), color: teal, radius: 2)
    drawText("⭐ Upgrade for the full clinical report",
             in: CGRect(x: M + 16, y: H - 100, width: CW - 24, height: 18),
             font: .boldSystemFont(ofSize: 13), color: navy)
    drawText("Multi-page report with charts, full episode log, time-of-day analysis & journal themes.",
             in: CGRect(x: M + 16, y: H - 78, width: CW - 24, height: 28),
             font: .systemFont(ofSize: 11), color: .darkGray)

    footer(page: 1, of: 1)
  }

  // MARK: - Premium Report

  private func drawPremiumReport(
    _ ctx: UIGraphicsPDFRendererContext,
    episodes: [TriggerEpisode],
    tracker: ProgressTracker,
    journal: [JournalEntry]
  ) {
    ctx.beginPage()
    drawCoverPage(episodes: episodes, tracker: tracker)
    footer(page: 1, of: nil)

    ctx.beginPage()
    drawEpisodesPage(ctx, episodes: episodes, startPage: 2)

    ctx.beginPage()
    drawAnalysisPage(episodes: episodes, page: 3)

    let unlocked = journal.filter { !$0.isLocked }
    if !unlocked.isEmpty {
      ctx.beginPage()
      drawJournalPage(unlocked, page: 4)
    }
  }

  // MARK: - Cover Page

  private func drawCoverPage(episodes: [TriggerEpisode], tracker: ProgressTracker) {
    // Navy header
    fill(CGRect(x: 0, y: 0, width: W, height: 190), color: navy)
    fill(CGRect(x: 0, y: 187, width: W, height: 4), color: teal)

    drawText("Relaxing Calm",
             in: CGRect(x: M, y: 44, width: CW, height: 40),
             font: .boldSystemFont(ofSize: 32), color: .white)
    drawText("Anxiety & Panic — Clinical Report",
             in: CGRect(x: M, y: 90, width: CW, height: 24),
             font: .systemFont(ofSize: 16), color: .white.withAlphaComponent(0.85))
    let dateStr = "Generated: " + DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
    drawText(dateStr, in: CGRect(x: M, y: 120, width: CW, height: 18),
             font: .systemFont(ofSize: 12), color: .white.withAlphaComponent(0.6))

    var y: CGFloat = 214

    // Data range
    if let oldest = episodes.sorted(by: { $0.timestamp < $1.timestamp }).first {
      let from = DateFormatter.localizedString(from: oldest.timestamp, dateStyle: .medium, timeStyle: .none)
      let to   = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
      drawText("Data range: \(from) – \(to)   ·   \(episodes.count) episode\(episodes.count == 1 ? "" : "s") total",
               in: CGRect(x: M, y: y, width: CW, height: 18),
               font: .systemFont(ofSize: 11), color: .darkGray)
    }
    y += 36

    // At a Glance stats
    sectionTitle("AT A GLANCE", y: &y)
    y += 4

    let week = episodes.filter {
      Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
    }.count
    let pct = episodes.isEmpty ? 0 : Int(Double(episodes.filter(\.isSuccess).count) / Double(episodes.count) * 100)

    let bw = (CW - 30) / 4
    let statData: [(String, String, UIColor)] = [
      ("\(episodes.count)", "Total\nEpisodes", navy),
      ("\(week)",            "This\nWeek",     navy),
      ("\(pct)%",            "Felt\nBetter",   UIColor(hex: "#1A5C50")),
      ("\(tracker.currentStreak)d", "Current\nStreak", UIColor(hex: "#7A4A10")),
    ]
    for (i, (val, lbl, col)) in statData.enumerated() {
      let x = M + CGFloat(i) * (bw + 10)
      let r = CGRect(x: x, y: y, width: bw, height: 88)
      fill(r, color: col.withAlphaComponent(0.08), radius: 10)
      stroke(r, color: col.withAlphaComponent(0.2), radius: 10)
      drawText(val,  in: CGRect(x: x + 4, y: y + 14, width: bw - 8, height: 36),
               font: .boldSystemFont(ofSize: 28), color: col, align: .center)
      drawText(lbl,  in: CGRect(x: x + 4, y: y + 52, width: bw - 8, height: 28),
               font: .systemFont(ofSize: 10), color: col.withAlphaComponent(0.7), align: .center)
    }
    y += 100

    // Relief outcome bar
    sectionTitle("RELIEF OUTCOMES", y: &y)
    let betterCount   = episodes.filter(\.isSuccess).count
    let neededCount   = episodes.count - betterCount
    let betterFrac    = episodes.isEmpty ? 0 : CGFloat(betterCount) / CGFloat(episodes.count)
    fill(CGRect(x: M, y: y, width: CW, height: 22), color: UIColor.red.withAlphaComponent(0.12), radius: 4)
    if betterFrac > 0 {
      fill(CGRect(x: M, y: y, width: CW * betterFrac, height: 22), color: teal.withAlphaComponent(0.65), radius: 4)
    }
    y += 30
    drawText("✅  Felt better: \(betterCount)",
             in: CGRect(x: M, y: y, width: CW / 2 - 8, height: 16),
             font: .systemFont(ofSize: 12), color: UIColor(hex: "#1A5C50"))
    drawText("⚠️  Needed more help: \(neededCount)",
             in: CGRect(x: M + CW / 2 + 8, y: y, width: CW / 2 - 8, height: 16),
             font: .systemFont(ofSize: 12), color: .darkGray)
    y += 30

    // Top triggers mini-chart
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    let counts = Dictionary(grouping: episodes.filter { $0.timestamp >= cutoff }, by: \.triggerKey).mapValues { $0.count }
    let top5 = counts.sorted { $0.value > $1.value }.prefix(5)
    if !top5.isEmpty {
      sectionTitle("TOP TRIGGERS  (last 30 days)", y: &y)
      let maxC = top5.first?.value ?? 1
      let barMaxW: CGFloat = CW - 168
      for (key, cnt) in top5 {
        if let cat = TriggerEpisode.categories.first(where: { $0.key == key }) {
          drawText(cat.emoji,   in: CGRect(x: M, y: y, width: 22, height: 18), font: .systemFont(ofSize: 13), color: .black)
          drawText(cat.label,   in: CGRect(x: M + 26, y: y, width: 116, height: 18), font: .systemFont(ofSize: 12), color: .darkGray)
          fill(CGRect(x: M + 146, y: y + 5, width: barMaxW * CGFloat(cnt) / CGFloat(maxC), height: 8), color: teal.withAlphaComponent(0.55), radius: 3)
          drawText("\(cnt)", in: CGRect(x: M + CW - 22, y: y, width: 22, height: 18), font: .systemFont(ofSize: 12), color: .darkGray, align: .right)
          y += 22
        }
      }
    }
  }

  // MARK: - Episodes Page

  private func drawEpisodesPage(
    _ ctx: UIGraphicsPDFRendererContext,
    episodes: [TriggerEpisode],
    startPage: Int
  ) {
    let cols: [(String, CGFloat, CGFloat)] = [
      ("Date & Time", M,       142),
      ("Trigger",     M + 142, 116),
      ("Time",        M + 258,  58),
      ("Sev.",        M + 316,  44),
      ("Outcome",     M + 360,  76),
      ("Note",        M + 436, CW - 252),
    ]

    func pageHeader(title: String) {
      fill(CGRect(x: 0, y: 0, width: W, height: 56), color: navy)
      drawText(title, in: CGRect(x: M, y: 14, width: CW, height: 28),
               font: .boldSystemFont(ofSize: 18), color: .white)
    }

    func columnHeaders(y: CGFloat) {
      fill(CGRect(x: M, y: y, width: CW, height: 22), color: teal.withAlphaComponent(0.1))
      for (title, x, w) in cols {
        drawText(title, in: CGRect(x: x + 4, y: y + 3, width: w - 8, height: 16),
                 font: .boldSystemFont(ofSize: 10), color: navy)
      }
    }

    pageHeader(title: "Panic Episodes — Full Log")
    var y: CGFloat = 66
    columnHeaders(y: y)
    y += 26

    let sorted = episodes.sorted { $0.timestamp > $1.timestamp }
    var pageNum = startPage

    for (i, ep) in sorted.enumerated() {
      if y > H - 72 {
        footer(page: pageNum, of: nil)
        ctx.beginPage()
        pageNum += 1
        pageHeader(title: "Panic Episodes — continued")
        y = 66
        columnHeaders(y: y)
        y += 26
      }

      let rowH: CGFloat = 22
      fill(CGRect(x: M, y: y, width: CW, height: rowH),
           color: i % 2 == 0 ? UIColor(white: 0.975, alpha: 1) : .white)
      drawText(ep.formattedTime, in: CGRect(x: M + 4, y: y + 3, width: 134, height: 16), font: .systemFont(ofSize: 10), color: .darkGray)
      drawText("\(ep.triggerEmoji) \(ep.triggerLabel)", in: CGRect(x: M + 146, y: y + 3, width: 108, height: 16), font: .systemFont(ofSize: 10), color: .black)
      drawText(ep.timeOfDayLabel, in: CGRect(x: M + 262, y: y + 3, width: 50, height: 16), font: .systemFont(ofSize: 10), color: .darkGray)
      if let sev = ep.severity {
        drawText("\(sev)/10", in: CGRect(x: M + 318, y: y + 3, width: 38, height: 16), font: .boldSystemFont(ofSize: 10), color: sev >= 7 ? UIColor(hex: "#C0514F") : sev >= 4 ? amber : teal)
      }
      let outcomeCol = ep.isSuccess ? teal : amber
      drawText(ep.isSuccess ? "Better ✓" : "Needed help",
               in: CGRect(x: M + 364, y: y + 3, width: 68, height: 16),
               font: .systemFont(ofSize: 10), color: outcomeCol)
      if let note = ep.note, !note.isEmpty {
        drawText(note, in: CGRect(x: M + 440, y: y + 3, width: CW - 256, height: 16),
                 font: .italicSystemFont(ofSize: 9), color: .darkGray)
      }

      // Row separator
      let line = UIBezierPath()
      line.move(to: CGPoint(x: M, y: y + rowH))
      line.addLine(to: CGPoint(x: M + CW, y: y + rowH))
      UIColor.lightGray.withAlphaComponent(0.35).setStroke()
      line.lineWidth = 0.5
      line.stroke()
      y += rowH
    }
    footer(page: pageNum, of: nil)
  }

  // MARK: - Analysis Page

  private func drawAnalysisPage(episodes: [TriggerEpisode], page: Int) {
    fill(CGRect(x: 0, y: 0, width: W, height: 56), color: navy)
    drawText("Trigger Analysis", in: CGRect(x: M, y: 14, width: CW, height: 28),
             font: .boldSystemFont(ofSize: 18), color: .white)

    var y: CGFloat = 76

    // Trigger frequency bars
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    let counts = Dictionary(grouping: episodes.filter { $0.timestamp >= cutoff }, by: \.triggerKey).mapValues { $0.count }
    let sorted = counts.sorted { $0.value > $1.value }

    sectionTitle("TRIGGER FREQUENCY  (last 30 days)", y: &y)
    if sorted.isEmpty {
      drawText("No episodes logged in the last 30 days.", in: CGRect(x: M, y: y, width: CW, height: 18),
               font: .systemFont(ofSize: 12), color: .darkGray)
      y += 22
    } else {
      let maxC = sorted.first?.value ?? 1
      let barMaxW: CGFloat = CW - 176
      for (key, cnt) in sorted {
        if let cat = TriggerEpisode.categories.first(where: { $0.key == key }) {
          drawText(cat.emoji,  in: CGRect(x: M, y: y, width: 20, height: 18), font: .systemFont(ofSize: 13), color: .black)
          drawText(cat.label,  in: CGRect(x: M + 24, y: y, width: 118, height: 18), font: .systemFont(ofSize: 12), color: .darkGray)
          fill(CGRect(x: M + 146, y: y + 5, width: barMaxW * CGFloat(cnt) / CGFloat(maxC), height: 8), color: teal.withAlphaComponent(0.55), radius: 3)
          drawText("\(cnt)", in: CGRect(x: M + CW - 22, y: y, width: 22, height: 18), font: .systemFont(ofSize: 12), color: .darkGray, align: .right)
          y += 22
        }
      }
    }
    y += 20

    // Time of day column chart
    sectionTitle("TIME OF DAY PATTERNS", y: &y)
    let timeCounts: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0].merging(
      Dictionary(grouping: episodes, by: \.timeOfDayLabel).mapValues { $0.count }
    ) { _, new in new }
    let timeMax = timeCounts.values.max() ?? 1
    let colW = CW / 4
    let maxBarH: CGFloat = 72
    let baseY = y + maxBarH + 20

    for (i, lbl) in ["Morning", "Afternoon", "Evening", "Night"].enumerated() {
      let cnt = timeCounts[lbl] ?? 0
      let bh  = timeMax > 0 ? maxBarH * CGFloat(cnt) / CGFloat(timeMax) : 4
      let x   = M + CGFloat(i) * colW + colW / 2 - 18
      fill(CGRect(x: x, y: baseY - bh, width: 36, height: bh), color: navy.withAlphaComponent(0.35), radius: 4)
      drawText("\(cnt)", in: CGRect(x: x, y: baseY - bh - 16, width: 36, height: 14),
               font: .boldSystemFont(ofSize: 11), color: navy, align: .center)
      drawText(lbl, in: CGRect(x: x - 12, y: baseY + 6, width: 60, height: 14),
               font: .systemFont(ofSize: 10), color: .darkGray, align: .center)
    }
    y = baseY + 30
    y += 24

    // Outcome per trigger
    sectionTitle("OUTCOME BY TRIGGER", y: &y)
    let grouped = Dictionary(grouping: episodes, by: \.triggerKey)
    let outcomes = grouped.compactMap { key, eps -> (TriggerEpisode.TriggerCategory, Int, Int)? in
      guard let cat = TriggerEpisode.categories.first(where: { $0.key == key }) else { return nil }
      return (cat, eps.filter(\.isSuccess).count, eps.count)
    }.sorted { $0.2 > $1.2 }.prefix(6)

    for (cat, better, total) in outcomes {
      let rate = total > 0 ? Int(Double(better) / Double(total) * 100) : 0
      drawText("\(cat.emoji) \(cat.label)", in: CGRect(x: M, y: y, width: 160, height: 18),
               font: .systemFont(ofSize: 12), color: .black)
      drawText("\(better)/\(total) felt better (\(rate)%)",
               in: CGRect(x: M + 168, y: y, width: CW - 168, height: 18),
               font: .systemFont(ofSize: 11), color: .darkGray)
      y += 22
    }

    footer(page: page, of: nil)
  }

  // MARK: - Journal Page

  private func drawJournalPage(_ journal: [JournalEntry], page: Int) {
    fill(CGRect(x: 0, y: 0, width: W, height: 56), color: navy)
    drawText("Journal Themes", in: CGRect(x: M, y: 14, width: CW, height: 28),
             font: .boldSystemFont(ofSize: 18), color: .white)

    var y: CGFloat = 76

    // Emotion frequency
    let emotions = journal.compactMap { $0.emotion }.filter { !$0.isEmpty }
    let emotionCounts = Dictionary(grouping: emotions, by: { $0 }).mapValues { $0.count }
    let topEmotions = emotionCounts.sorted { $0.value > $1.value }.prefix(6)
    if !topEmotions.isEmpty {
      sectionTitle("MOST COMMON EMOTIONS", y: &y)
      for (emotion, count) in topEmotions {
        kvLine(emotion.capitalized, value: "\(count)×", y: &y)
      }
      y += 14
    }

    // Contributing factors
    let factors = journal.compactMap { $0.contributingFactors }.flatMap { $0 }
    let factorCounts = Dictionary(grouping: factors, by: { $0 }).mapValues { $0.count }
    let topFactors = factorCounts.sorted { $0.value > $1.value }.prefix(5)
    if !topFactors.isEmpty {
      sectionTitle("CONTRIBUTING FACTORS", y: &y)
      for (factor, count) in topFactors {
        bullet("• \(factor.capitalized)  (\(count)×)", y: &y)
      }
      y += 14
    }

    // Recent journal snippets
    sectionTitle("RECENT JOURNAL ENTRIES  (last 5)", y: &y)
    for entry in journal.sorted(by: { $0.timestamp > $1.timestamp }).prefix(5) {
      let dateStr = DateFormatter.localizedString(from: entry.timestamp, dateStyle: .medium, timeStyle: .short)
      drawText(dateStr, in: CGRect(x: M, y: y, width: CW, height: 15),
               font: .boldSystemFont(ofSize: 11), color: navy)
      y += 17
      let snippet = String(entry.content.prefix(200)) + (entry.content.count > 200 ? "…" : "")
      let snipH = drawText(snippet, in: CGRect(x: M + 10, y: y, width: CW - 10, height: 56),
                           font: .systemFont(ofSize: 11), color: .darkGray)
      y += snipH + 10

      let sep = UIBezierPath()
      sep.move(to: CGPoint(x: M, y: y))
      sep.addLine(to: CGPoint(x: M + CW, y: y))
      UIColor.lightGray.withAlphaComponent(0.45).setStroke()
      sep.lineWidth = 0.5
      sep.stroke()
      y += 10
    }

    footer(page: page, of: nil)
  }

  // MARK: - Drawing Primitives

  @discardableResult
  private func drawText(
    _ str: String,
    in rect: CGRect,
    font: UIFont,
    color: UIColor,
    align: NSTextAlignment = .left
  ) -> CGFloat {
    let para = NSMutableParagraphStyle()
    para.alignment = align
    para.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: para]
    let astr = NSAttributedString(string: str, attributes: attrs)
    astr.draw(in: rect)
    return astr.boundingRect(with: CGSize(width: rect.width, height: 2000),
                             options: .usesLineFragmentOrigin, context: nil).height
  }

  private func fill(_ rect: CGRect, color: UIColor, radius: CGFloat = 0) {
    let path = radius > 0 ? UIBezierPath(roundedRect: rect, cornerRadius: radius) : UIBezierPath(rect: rect)
    color.setFill()
    path.fill()
  }

  private func stroke(_ rect: CGRect, color: UIColor, radius: CGFloat = 0) {
    let path = radius > 0 ? UIBezierPath(roundedRect: rect, cornerRadius: radius) : UIBezierPath(rect: rect)
    color.setStroke()
    path.lineWidth = 1
    path.stroke()
  }

  private func sectionTitle(_ title: String, y: inout CGFloat) {
    drawText(title, in: CGRect(x: M, y: y, width: CW, height: 16),
             font: .systemFont(ofSize: 10, weight: .semibold), color: teal)
    let line = UIBezierPath()
    line.move(to: CGPoint(x: M, y: y + 17))
    line.addLine(to: CGPoint(x: M + CW, y: y + 17))
    teal.withAlphaComponent(0.3).setStroke()
    line.lineWidth = 0.5
    line.stroke()
    y += 24
  }

  private func kvLine(_ label: String, value: String, y: inout CGFloat) {
    drawText(label,  in: CGRect(x: M + 8, y: y, width: CW - 80, height: 18),
             font: .systemFont(ofSize: 12), color: .darkGray)
    drawText(value,  in: CGRect(x: M + 8, y: y, width: CW - 8, height: 18),
             font: .boldSystemFont(ofSize: 12), color: navy, align: .right)
    y += 20
  }

  private func bullet(_ text: String, y: inout CGFloat) {
    drawText(text, in: CGRect(x: M + 8, y: y, width: CW - 8, height: 18),
             font: .systemFont(ofSize: 12), color: .darkGray)
    y += 20
  }

  private func footer(page: Int, of total: Int?) {
    fill(CGRect(x: 0, y: H - 34, width: W, height: 34), color: UIColor(white: 0.97, alpha: 1))
    let pageStr = total != nil ? "Page \(page) of \(total!)" : "Page \(page)"
    drawText("Relaxing Calm — Confidential patient report",
             in: CGRect(x: M, y: H - 22, width: CW * 0.65, height: 14),
             font: .systemFont(ofSize: 9), color: .lightGray)
    drawText(pageStr, in: CGRect(x: M, y: H - 22, width: CW, height: 14),
             font: .systemFont(ofSize: 9), color: .lightGray, align: .right)
  }
}

// MARK: - UIColor+Hex (local)

private extension UIColor {
  convenience init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    self.init(
      red:   CGFloat((int >> 16) & 0xFF) / 255,
      green: CGFloat((int >> 8)  & 0xFF) / 255,
      blue:  CGFloat( int        & 0xFF) / 255,
      alpha: 1
    )
  }
}
