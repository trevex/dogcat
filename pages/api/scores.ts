// Next.js API route support: https://nextjs.org/docs/api-routes/introduction
import type { NextApiRequest, NextApiResponse } from 'next'
import { Score } from "../../models";

type Error = {
    message: string;
};

export default async function handler(
    req: NextApiRequest,
    res: NextApiResponse<Score[] | Error>
) {
    if (req.method === 'POST') { // If method was POST, we also add a new score!
        const username = "foobar"; // TODO: get from IAP header
        const {
            score,
        } = req.body;
        if (typeof score !== "number") {
            res.status(400).send({ message: 'Required argument not provided!' });
            return;
        }
        Date.now()
        await Score.create({
            username,
            score,
        });
    }

    // We always return the scores...
    const scores = await Score.findAll({ limit: 20 });
    res.status(200).json(scores.map((s) => s.toJSON()));
}
