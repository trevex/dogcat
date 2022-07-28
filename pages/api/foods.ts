import type { NextApiRequest, NextApiResponse } from 'next';
import { Controller, Food } from "../../components/GameProvider";

type Error = {
    message: string;
};

type Data = {
    tickRate: number;
    foods: Food[];
};

const minFood = 2;
const maxFood = 8;
const minTickRate = 200;
const maxTickRate = 30;

const foodMap: { [name: string]: Controller; } = {
    "sausage": Controller.Dog,
    "fish": Controller.Cat,
};

export default async function handler(
    req: NextApiRequest,
    res: NextApiResponse<Data | Error>
) {
    if (req.method !== 'POST') {
        res.status(405).send({ message: 'Only POST allowed!' });
        return;
    }

    const {
        length,
        updateCount,
    } = req.body;
    if (typeof length !== "number" || typeof updateCount !== "number") {
        res.status(400).send({ message: 'Required arguments not provided!' });
        return;
    }

    const factor = Math.max(Math.min((length / 30 + updateCount / 200) / 2, 1.0), 0.0);
    let foodAmount = Math.round(minFood + (maxFood - minFood) * factor);
    const tickRate = Math.round(minTickRate + (maxTickRate - minTickRate) * factor);

    let foods: Food[] = [];
    const foodNames = Object.keys(foodMap);
    while (foodAmount--) {
        const foodName = foodNames[Math.floor(Math.random() * foodNames.length)];
        foods.push([{ x: 0, y: 0 }, foodName, foodMap[foodName]]);
    }

    res.status(200).json({ foods, tickRate });
}
