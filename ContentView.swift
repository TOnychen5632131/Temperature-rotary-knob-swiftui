import SwiftUI

struct ContentView: View {

    // ========== 尺寸配置，可按需调整 ==========
    let OUTER_CIRCLE_SIZE: CGFloat = 260    // 最外层白圈 + 阴影 的直径
    let DIAL_SIZE: CGFloat = 190           // 中间可旋转表盘的直径
    let STROKE_WIDTH: CGFloat = 20         // 灰色/紫色环的宽度
    let HANDLE_RADIUS: CGFloat = 15        // 把手外圈半径
    let INNER_DOT_RADIUS: CGFloat = 5      // 把手内圈紫点的半径

    let MIN_TEMPERATURE: Int = 16
    let MAX_TEMPERATURE: Int = 30
    let INITIAL_TEMPERATURE: Int = 27

    // ========== 颜色（使用 RGB 初始化，无需额外 Assets） ==========

    /// 最外层大圆背景色（白色）
    let colorOuterBG = Color(red: 1, green: 1, blue: 1)  // #ffffff

    /// 页面背景 (浅灰)
    let colorPageBG  = Color(red: 245/255, green: 245/255, blue: 245/255)  // #f5f5f5

    /// 滑道颜色 (灰) #eceef4
    let colorTrack   = Color(red: 236/255, green: 238/255, blue: 244/255)

    /// 进度环 / 把手边框 / 中间点 (紫) #5d68d8
    let colorActive  = Color(red: 93/255, green: 104/255, blue: 216/255)

    /// 文字颜色 (#0c0d33)
    let colorText    = Color(red: 12/255, green: 13/255, blue: 51/255)

    // ========== 状态：温度 和 角度 ==========
    @State private var temperature: Int = 27
    @State private var angle: CGFloat = 0

    var body: some View {
        ZStack {
            // 整个页面背景
            colorPageBG
                .edgesIgnoringSafeArea(.all)

            // 最外层白圈 + 阴影
            ZStack {
                Circle()
                    .fill(colorOuterBG)
                    .frame(width: OUTER_CIRCLE_SIZE, height: OUTER_CIRCLE_SIZE)
                    // SwiftUI 的阴影
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)

                // 中间表盘 (可旋转)
                DialView(
                    dialSize: DIAL_SIZE,
                    strokeWidth: STROKE_WIDTH,
                    handleRadius: HANDLE_RADIUS,
                    innerDotRadius: INNER_DOT_RADIUS,
                    minTemp: MIN_TEMPERATURE,
                    maxTemp: MAX_TEMPERATURE,
                    temperature: $temperature,
                    angle: $angle,
                    colorTrack: colorTrack,
                    colorActive: colorActive,
                    colorText: colorText
                )
            }
        }
        .onAppear {
            // 初始化 temperature / angle
            temperature = INITIAL_TEMPERATURE
            angle = mapTempToAngle(temp: INITIAL_TEMPERATURE)
        }
    }

    // MARK: - 温度 → 角度
    func mapTempToAngle(temp: Int) -> CGFloat {
        let range = CGFloat(MAX_TEMPERATURE - MIN_TEMPERATURE)
        let ratio = CGFloat(temp - MIN_TEMPERATURE) / range
        return ratio * 360
    }
}

// MARK: - DialView
struct DialView: View {
    let dialSize: CGFloat
    let strokeWidth: CGFloat
    let handleRadius: CGFloat
    let innerDotRadius: CGFloat

    let minTemp: Int
    let maxTemp: Int

    // 与父视图共享的 @State
    @Binding var temperature: Int
    @Binding var angle: CGFloat

    // 注入颜色
    let colorTrack: Color
    let colorActive: Color
    let colorText: Color

    // 计算当前进度 (0~1)
    var fraction: CGFloat {
        angle / 360
    }

    // 添加一个状态来追踪拖拽起始角度
    @State private var dragStartAngle: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. 灰色滑道 (全圈)
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(colorTrack,
                            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    .frame(width: dialSize, height: dialSize)

                // 2. 紫色进度 (依据 fraction)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(colorActive,
                            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    .frame(width: dialSize, height: dialSize)
                    // 让进度从顶部开始
                    .rotationEffect(.degrees(-90))

                // 3. 把手 (白色外圈 + 紫色边 + 阴影)
                Circle()
                    .fill(Color.white)
//                    .overlay(
//                        Circle().stroke(colorActive, lineWidth: 3)
//                    )
                    .frame(width: handleRadius * 2, height: handleRadius * 2)
                    .position(handlePosition(in: geo.size))
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 2, y: 2)

                // 4. 把手中心紫点
                Circle()
                    .fill(colorActive)
                    .frame(width: innerDotRadius * 2, height: innerDotRadius * 2)
                    .position(handlePosition(in: geo.size))

                // 5. 中心文字
                VStack(spacing: 6) {
                    // "27 °C"
                    HStack(spacing: 4) {
                        Text("\(temperature)")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(colorText)
                        Text("°C")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(colorText)
                    }
                    Text("温度")
                        .font(.system(size: 16))
                        .foregroundColor(colorText)
                }
            }
            // 修改拖拽手势的处理
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if value.translation == .zero {
                            // 开始拖拽时记录起始角度
                            dragStartAngle = angle
                        }
                        
                        let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                        let dragPoint = value.location
                        
                        // 计算拖拽点相对于中心的角度
                        let dragAngle = atan2(dragPoint.y - center.y, dragPoint.x - center.x) * 180 / .pi
                        var newAngle = dragAngle + 90 // 调整为以 12 点钟方向为 0 度
                        if newAngle < 0 { newAngle += 360 }
                        
                        updateTempAngle(newAngle)
                    }
            )
        }
        .frame(width: dialSize, height: dialSize)
    }

    // 计算把手在 dialSize 内的中心点
    func handlePosition(in size: CGSize) -> CGPoint {
        let rad = (angle - 90) * .pi / 180   // 让 0°从顶部开始
        let r = (dialSize - strokeWidth) / 1.8
        let cx = size.width / 2
        let cy = size.height / 2

        let x = cx + r * cos(rad)
        let y = cy + r * sin(rad)
        return CGPoint(x: x, y: y)
    }

    // 将 cartesian 坐标转换为 [0,360) 角度
    func cartesianToAngle(_ point: CGPoint) -> CGFloat {
        var degrees = atan2(point.y, point.x) * 180 / .pi
        if degrees < 0 { degrees += 360 }
        return degrees
    }

    // 更新温度 & 角度 (限制到 [minTemp, maxTemp])
    func updateTempAngle(_ newAngle: CGFloat) {
        let newTemp = mapAngleToTemp(newAngle)
        if newTemp < minTemp {
            temperature = minTemp
            angle = mapTempToAngle(minTemp)
        } else if newTemp > maxTemp {
            temperature = maxTemp
            angle = mapTempToAngle(maxTemp)
        } else {
            temperature = newTemp
            angle = newAngle
        }
    }

    // 映射：角度 → 温度
    func mapAngleToTemp(_ ang: CGFloat) -> Int {
        let range = maxTemp - minTemp
        let val = CGFloat(minTemp) + (ang / 360) * CGFloat(range)
        return Int(round(val))
    }

    // 映射：温度 → 角度
    func mapTempToAngle(_ temp: Int) -> CGFloat {
        let range = maxTemp - minTemp
        let ratio = CGFloat(temp - minTemp) / CGFloat(range)
        return ratio * 360
    }
}
