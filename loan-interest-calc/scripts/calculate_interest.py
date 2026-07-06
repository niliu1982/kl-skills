"""
贷款利息计算器 — 等额本息还款法
公式：总利息 = (还款期数 + 1) × 贷款总额 × 期利率 ÷ 2
"""

import argparse
import sys
import io

# Windows 控制台编码兼容
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# 中国人民银行贷款基准利率（年利率）
RATE_TABLE = [
    (1, 4.35),    # 一年以内（含一年）
    (5, 4.75),    # 一年至五年（含五年）
    (float("inf"), 4.90),  # 五年以上
]


def get_annual_rate(years: float) -> tuple[float, str]:
    """根据贷款年限匹配年利率。"""
    for max_years, rate in RATE_TABLE:
        if years <= max_years:
            tier_desc = (
                f"一年以内（含一年） {rate}%"
                if max_years == 1
                else f"一年至五年（含五年） {rate}%"
                if max_years == 5
                else f"五年以上 {rate}%"
            )
            return rate / 100, tier_desc
    # 不应到达这里
    return 0.049, "未知"


def calculate(loan_amount: float, years: float, freq: str = "monthly") -> dict:
    """
    计算贷款利息。

    loan_amount: 贷款总额（元）
    years: 贷款年限
    freq: 还款频率 "monthly"（月供）或 "yearly"（年供）
    """
    periods_per_year = 12 if freq == "monthly" else 1
    total_periods = int(years * periods_per_year)

    annual_rate, tier_desc = get_annual_rate(years)
    period_rate = annual_rate / periods_per_year

    # 总利息 = (还款期数 + 1) × 贷款总额 × 期利率 ÷ 2
    total_interest = (total_periods + 1) * loan_amount * period_rate / 2
    total_repayment = loan_amount + total_interest
    per_period_repayment = total_repayment / total_periods
    per_period_interest = total_interest / total_periods

    return {
        "loan_amount": loan_amount,
        "years": years,
        "freq": freq,
        "freq_label": "月" if freq == "monthly" else "年",
        "total_periods": total_periods,
        "annual_rate": annual_rate * 100,
        "tier_desc": tier_desc,
        "period_rate": period_rate * 100,
        "total_interest": round(total_interest, 2),
        "total_repayment": round(total_repayment, 2),
        "per_period_repayment": round(per_period_repayment, 2),
        "per_period_interest": round(per_period_interest, 2),
    }


def format_result(r: dict) -> str:
    """格式化输出结果。"""
    freq_label = r["freq_label"]
    if r["freq"] == "monthly":
        freq_name = "月供"
    else:
        freq_name = "年供"

    lines = [
        "=" * 50,
        "          贷款利息计算结果（等额本息）",
        "=" * 50,
        f" 贷款总额         : ¥{r['loan_amount']:,.2f}",
        f" 贷款年限         : {r['years']} 年",
        f" 还款方式         : {freq_name}（共 {r['total_periods']} 期）",
        f" 适用利率档次     : {r['tier_desc']}",
        f" 年利率           : {r['annual_rate']}%",
        f" 期利率           : {r['period_rate']:.4f}%",
        "-" * 50,
        f" 每期还款额       : ¥{r['per_period_repayment']:,.2f}",
        f"   - 其中本金     : ¥{r['loan_amount'] / r['total_periods']:,.2f}",
        f"   - 其中利息     : ¥{r['per_period_interest']:,.2f}",
        "-" * 50,
        f" 总利息           : ¥{r['total_interest']:,.2f}",
        f" 总还款额         : ¥{r['total_repayment']:,.2f}",
        "=" * 50,
    ]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="贷款利息计算器（等额本息）")
    parser.add_argument("amount", type=float, help="贷款总额（元）")
    parser.add_argument("years", type=float, help="贷款年限")
    parser.add_argument(
        "--freq",
        choices=["monthly", "yearly"],
        default="monthly",
        help="还款频率：monthly=月供（默认），yearly=年供",
    )
    args = parser.parse_args()

    if args.amount <= 0:
        print("错误：贷款总额必须大于 0", file=sys.stderr)
        sys.exit(1)
    if args.years <= 0:
        print("错误：贷款年限必须大于 0", file=sys.stderr)
        sys.exit(1)

    result = calculate(args.amount, args.years, args.freq)
    print(format_result(result))


if __name__ == "__main__":
    main()
